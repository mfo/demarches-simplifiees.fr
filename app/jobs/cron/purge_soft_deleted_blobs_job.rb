# frozen_string_literal: true

class Cron::PurgeSoftDeletedBlobsJob < Cron::CronJob
  self.schedule_expression = "every day at 01:00" # after PurgeUnattachedBlobsJob (00:30)

  # Swift bulk delete accepts up to 10_000 objects per request; stay well under.
  BULK_DELETE_LIMIT = 1000

  def perform
    return if ENV['PURGE_LATER_DELAY_IN_DAY'].blank?
    return if ActiveStorage::Blob.service.name != :openstack

    retention = Integer(ENV['PURGE_LATER_DELAY_IN_DAY']).days

    ActiveStorage::Blob
      .where(service_name: :openstack, soft_delete_at: ..retention.ago)
      .in_batches(of: BULK_DELETE_LIMIT) { purge_batch(it.ids) }
  end

  private

  # For a batch of expired blobs
  # - add all the related variant blobs
  # - delete all the corresponding files on the bucket
  # - delete in db attachment / variant / blob
  def purge_batch(parent_ids)
    variant_record_ids = ActiveStorage::VariantRecord.where(blob_id: parent_ids).ids
    image_attachments = ActiveStorage::Attachment
      .where(record_type: 'ActiveStorage::VariantRecord', record_id: variant_record_ids)
    blob_ids = image_attachments.pluck(:blob_id) + parent_ids

    delete_files(blob_ids)

    # delete_all bypasses callbacks, so we drop the rows ourselves, in FK order:
    # image attachments -> variant records -> blobs (variants + parents).
    image_attachments.delete_all
    ActiveStorage::VariantRecord.where(id: variant_record_ids).delete_all
    ActiveStorage::Blob.where(id: blob_ids).delete_all
  end

  def delete_files(blob_ids)
    keys = ActiveStorage::Blob.where(id: blob_ids).pluck(:key)

    service = ActiveStorage::Blob.service
    client = service.send(:client)

    keys.each_slice(BULK_DELETE_LIMIT) do |slice|
      response = client.delete_multiple_objects(service.container, slice)
      errors = response.body['Errors']
      Sentry.capture_message("Bulk delete errors", extra: { errors: }) if errors.present?
    end
  end
end
