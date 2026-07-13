# frozen_string_literal: true

class BlobService
  # Swift bulk delete accepts up to 10_000 objects per request; stay well under.
  BULK_DELETE_LIMIT = 1000

  class << self
    # For a batch of expired blobs
    # - keep only the openstack ones (never touch rows/files from another service)
    # - add all the related variant blobs
    # - delete the corresponding files on the openstack bucket
    # - delete in db attachment / variant / blob
    def purge_blobs_with_variants(parent_ids)
      parent_ids = ActiveStorage::Blob.where(id: parent_ids, service_name: :openstack).ids

      variant_record_ids = ActiveStorage::VariantRecord.where(blob_id: parent_ids).ids
      variant_attachments = ActiveStorage::Attachment
        .where(record_type: 'ActiveStorage::VariantRecord', record_id: variant_record_ids)
      blob_ids = variant_attachments.pluck(:blob_id) + parent_ids

      delete_files(blob_ids)

      # delete_all bypasses callbacks, so we drop the rows ourselves, in FK order:
      # image attachments -> variant records -> blobs (variants + parents).
      variant_attachments.delete_all
      ActiveStorage::VariantRecord.where(id: variant_record_ids).delete_all
      ActiveStorage::Blob.where(id: blob_ids).delete_all
    end

    private

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
end
