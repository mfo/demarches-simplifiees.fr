# frozen_string_literal: true

class Cron::PurgeSoftDeletedBlobsJob < Cron::CronJob
  self.schedule_expression = "every day at 01:00" # after PurgeUnattachedBlobsJob (00:30)

  def perform
    return if ENV['PURGE_LATER_DELAY_IN_DAY'].blank?
    return if ActiveStorage::Blob.service.name != :openstack

    retention = Integer(ENV['PURGE_LATER_DELAY_IN_DAY']).days

    ActiveStorage::Blob
      .where(service_name: :openstack, soft_deleted_at: ..retention.ago)
      .in_batches(of: BlobService::BULK_DELETE_LIMIT) { BlobService.purge_blobs_with_variants(it.ids) }
  end
end
