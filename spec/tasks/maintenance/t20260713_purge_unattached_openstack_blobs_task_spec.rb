# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260713PurgeUnattachedOpenstackBlobsTask do
    describe '#collection' do
      it 'returns a batch enumerator scoped to openstack blobs' do
        collection = described_class.new.collection
        expect(collection).to be_a(ActiveRecord::Batches::BatchEnumerator)
        expect(collection.relation.to_sql).to include("service_name").and include("openstack")
      end
    end

    describe '#process' do
      let!(:unattached_blob) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("orphan"), filename: "o.txt", content_type: "text/plain")
          .tap { it.update_column(:created_at, 2.days.ago) }
      end

      let!(:attached_blob) do
        blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("kept"), filename: "k.txt", content_type: "text/plain")
        ActiveStorage::Attachment.create!(name: "file", record: dossiers.en_construction, blob:)
        blob
      end

      def process
        described_class.new.process(ActiveStorage::Blob.where(id: [unattached_blob.id, attached_blob.id]))
      end

      it 'delegates the unattached blob to BlobService, leaving out the attached one' do
        expect(BlobService).to receive(:purge_blobs_with_variants).with([unattached_blob.id])

        process
      end

      it 'logs each purged blob to the log file as JSON' do
        entry = { id: unattached_blob.id, key: unattached_blob.key, file_deleted: true, variant: false, parent_id: nil }
        allow(BlobService).to receive(:purge_blobs_with_variants).and_yield(entry)

        fake_logger = instance_double(Logger)
        allow(Logger).to receive(:new).with(described_class::LOG_PATH).and_return(fake_logger)
        expect(fake_logger).to receive(:info).with(entry.to_json)

        process
      end

      it 'does not call BlobService when the batch has no orphan' do
        expect(BlobService).not_to receive(:purge_blobs_with_variants)

        described_class.new.process(ActiveStorage::Blob.where(id: attached_blob.id))
      end

      it 'leaves out a recently created orphan (may still be getting attached)' do
        unattached_blob.update_column(:created_at, 1.hour.ago)

        expect(BlobService).not_to receive(:purge_blobs_with_variants)

        process
      end

      it 'leaves out a soft-deleted orphan' do
        unattached_blob.update_column(:soft_deleted_at, Time.current)

        expect(BlobService).not_to receive(:purge_blobs_with_variants)

        process
      end
    end
  end
end
