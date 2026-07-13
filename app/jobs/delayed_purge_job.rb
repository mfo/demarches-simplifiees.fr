# frozen_string_literal: true

class DelayedPurgeJob < ApplicationJob
  queue_as :low

  # when storage is down, errors come in a variety of forms
  with_options(wait: :polynomially_longer, attempts: MAX_ATTEMPTS_JOBS) do
    retry_on Excon::Error::BadGateway
    retry_on Excon::Error::ServiceUnavailable
    retry_on Excon::Error::InternalServerError
    retry_on Excon::Error::Timeout
    retry_on Excon::Error::RequestTimeout
    retry_on Excon::Error::ServiceUnavailable
  end

  rescue_from Excon::Error::RequestEntityTooLarge do
    blob.purge
  end

  # rate limit reached
  retry_on Excon::Error::TooManyRequests, wait: 10.minutes, attempts: MAX_ATTEMPTS_JOBS

  # can discard
  discard_on ActiveJob::DeserializationError
  discard_on ActiveRecord::RecordNotFound

  require 'fog/openstack'
  discard_on Fog::OpenStack::Storage::NotFound

  delegate :service, :key, to: :blob
  delegate :container, to: :service

  attr_reader :blob

  def perform(blob)
    @blob = blob
    if !soft_delete_enabled?
      blob.purge
    else
      soft_delete
    end
  end

  private

  def delay = Integer(ENV['PURGE_LATER_DELAY_IN_DAY']).day.from_now.to_i

  # head object to update metadata makes pj unreadable. copy with extra headers
  def soft_delete
    # ActiveStorage removes attachments first and then calls purge (or purge_later) on the blob.
    # In a before_destroy hook, it checks if any attachments still exist. If no attachments are left, it deletes the blob.
    # We should replicate the same behavior here.
    # https://github.com/rails/rails/blob/ef88965e8a0c72496c210a5a0a48b85ec9a2ed17/activestorage/app/models/active_storage/blob.rb#L53-L55
    return if blob.attachments.exists?
    return if !expire_file(blob)

    blob.update_column(:soft_deleted_at, Time.current)
    soft_delete_variants if blob.image?
  end

  def soft_delete_variants
    variant_blob_ids = ActiveStorage::Attachment
      .where(record_type: 'ActiveStorage::VariantRecord', record_id: blob.variant_records.ids)
      .pluck(:blob_id)

    ActiveStorage::Blob.where(id: variant_blob_ids).find_each { expire_file(it) }
  end

  # Copy the blob's file onto itself with an X-Delete-At header so Swift expires
  # it after the retention delay. Returns whether Swift accepted the request and
  # reports to Sentry on failure.
  def expire_file(blob)
    headers = { "Content-Type" => blob.content_type, 'X-Delete-At' => delay.to_s }
    return true if client.copy_object(container, blob.key, container, blob.key, headers).status == 201

    Sentry.capture_message("Can't expire blob", extra: { key: blob.key, headers: })
    false
  end

  def soft_delete_enabled?
    openstack? && delay.positive?
  rescue
    false
  end

  def openstack? = service.name == :openstack

  def client
    service.send(:client)
  end
end
