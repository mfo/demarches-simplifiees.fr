# frozen_string_literal: true

RSpec.describe BlobService do
  describe '.purge_blobs_with_variants' do
    # Blobs are created against the real (disk) service, then flipped to openstack
    # and purged against a mocked openstack service — installed by the subject,
    # once every blob exists.
    subject(:purge_blobs_with_variants) do
      service = double('openstack service', container: 'bucket', name: :openstack)
      allow(service).to receive(:client).and_return(client) # reached via service.send(:client)
      allow(ActiveStorage::Blob).to receive(:service).and_return(service)
      BlobService.purge_blobs_with_variants([blob.id])
    end

    let(:client) { double('openstack client') }

    let!(:blob) do
      ActiveStorage::Blob.create_and_upload!(io: StringIO.new("old"), filename: "old.txt", content_type: "text/plain")
        .tap { it.update_column(:service_name, 'openstack') }
    end

    before do
      allow(client).to receive(:delete_multiple_objects).and_return(double(body: { 'Errors' => [] }))
    end

    it 'drops the blob row' do
      expect { purge_blobs_with_variants }.to change { ActiveStorage::Blob.exists?(id: blob.id) }.from(true).to(false)
    end

    it 'bulk-deletes the parent file (safety net against a missed X-Delete-At)' do
      expect(client).to receive(:delete_multiple_objects)
        .with('bucket', [blob.key])
        .and_return(double(body: { 'Errors' => [] }))

      purge_blobs_with_variants
    end

    context 'when the blob is an image with variants' do
      let!(:variant_blob) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("variant"), filename: "v.png", content_type: "image/png")
          .tap { it.update_column(:service_name, 'openstack') }
      end
      let!(:variant_record) { ActiveStorage::VariantRecord.create!(blob:, variation_digest: "digest") }
      let!(:image_attachment) { ActiveStorage::Attachment.create!(name: "image", record: variant_record, blob: variant_blob) }

      it 'bulk-deletes both variant and parent files, then drops every row' do
        expect(client).to receive(:delete_multiple_objects)
          .with('bucket', match_array([variant_blob.key, blob.key]))
          .and_return(double(body: { 'Errors' => [] }))

        purge_blobs_with_variants

        expect(ActiveStorage::Blob.where(id: [blob.id, variant_blob.id])).not_to exist
        expect(ActiveStorage::VariantRecord.where(id: variant_record.id)).not_to exist
        expect(ActiveStorage::Attachment.where(id: image_attachment.id)).not_to exist
      end

      it 'reports per-object bulk delete errors to Sentry' do
        errors = [["bucket/#{variant_blob.key}", "409 Conflict"]]
        allow(client).to receive(:delete_multiple_objects).and_return(double(body: { 'Errors' => errors }))

        expect(Sentry).to receive(:capture_message).with("Bulk delete errors", extra: { errors: })

        purge_blobs_with_variants
      end
    end

    context 'when the blob is stored on another service' do
      let!(:blob) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("other"), filename: "other.txt", content_type: "text/plain")
      end

      it 'leaves its file and row untouched' do
        expect(client).not_to receive(:delete_multiple_objects)

        expect { purge_blobs_with_variants }.not_to change { ActiveStorage::Blob.exists?(id: blob.id) }
      end
    end
  end
end
