# frozen_string_literal: true

RSpec.describe Cron::PurgeSoftDeletedBlobsJob, type: :job do
  describe 'perform' do
    # Blobs are created against the real (disk) service, then the job runs against
    # a mocked OpenStack service — hence the helper, called from each example once
    # every blob exists.
    subject(:perform) do
      service = double('openstack service', container: 'bucket', name: :openstack)
      allow(service).to receive(:client).and_return(client) # reached via service.send(:client)
      allow(ActiveStorage::Blob).to receive(:service).and_return(service)
      described_class.perform_now
    end

    let(:client) { double('openstack client') }

    before do
      stub_const('ENV', ENV.to_hash.merge('PURGE_LATER_DELAY_IN_DAY' => '1'))
      allow(client).to receive(:delete_multiple_objects).and_return(double(body: { 'Errors' => [] }))
    end

    # retention = PURGE_LATER_DELAY_IN_DAY = 1.day
    let(:blob_old) do
      ActiveStorage::Blob.create_and_upload!(io: StringIO.new("old"), filename: "old.txt", content_type: "text/plain").tap do |blob|
        blob.update_columns(soft_delete_at: 2.days.ago, service_name: 'openstack')
      end
    end

    let(:blob_recent) do
      ActiveStorage::Blob.create_and_upload!(io: StringIO.new("recent"), filename: "recent.txt", content_type: "text/plain").tap do |blob|
        blob.update_column(:soft_delete_at, 1.hour.ago)
      end
    end

    let(:blob_never_soft_deleted) do
      ActiveStorage::Blob.create_and_upload!(io: StringIO.new("kept"), filename: "kept.txt", content_type: "text/plain")
    end

    before do
      blob_old
      blob_recent
      blob_never_soft_deleted
    end

    it 'destroys blobs soft-deleted long enough ago' do
      expect { perform }.to change { ActiveStorage::Blob.exists?(id: blob_old.id) }.from(true).to(false)
    end

    it 'keeps recently soft-deleted and never-soft-deleted blobs' do
      perform
      expect(ActiveStorage::Blob.exists?(id: blob_recent.id)).to be(true)
      expect(ActiveStorage::Blob.exists?(id: blob_never_soft_deleted.id)).to be(true)
    end

    it 'keeps blobs stored on another service' do
      blob_other_service = ActiveStorage::Blob
        .create_and_upload!(io: StringIO.new("other"), filename: "other.txt", content_type: "text/plain")
        .tap { it.update_columns(soft_delete_at: 2.days.ago, service_name: 'test') }

      perform

      expect(ActiveStorage::Blob.exists?(id: blob_other_service.id)).to be(true)
    end

    it 'does nothing when the storage service is not OpenStack' do
      allow(ActiveStorage::Blob).to receive(:service).and_return(double('disk service', name: :test))

      expect { described_class.perform_now }.not_to change(ActiveStorage::Blob, :count)
    end

    it 'bulk-deletes the parent file (safety net against a missed X-Delete-At)' do
      expect(client).to receive(:delete_multiple_objects)
        .with('bucket', [blob_old.key])
        .and_return(double(body: { 'Errors' => [] }))

      perform
    end

    context 'when a soft-deleted image has variants' do
      let!(:variant_blob) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("variant"), filename: "v.png", content_type: "image/png")
      end
      let!(:variant_record) { ActiveStorage::VariantRecord.create!(blob: blob_old, variation_digest: "digest") }
      let!(:image_attachment) { ActiveStorage::Attachment.create!(name: "image", record: variant_record, blob: variant_blob) }

      it 'bulk-deletes both variant and parent files, then drops every row' do
        expect(client).to receive(:delete_multiple_objects)
          .with('bucket', match_array([variant_blob.key, blob_old.key]))
          .and_return(double(body: { 'Errors' => [] }))

        perform

        expect(ActiveStorage::Blob.where(id: [blob_old.id, variant_blob.id])).not_to exist
        expect(ActiveStorage::VariantRecord.where(id: variant_record.id)).not_to exist
        expect(ActiveStorage::Attachment.where(id: image_attachment.id)).not_to exist
      end

      it 'reports per-object bulk delete errors to Sentry' do
        errors = [["bucket/#{variant_blob.key}", "409 Conflict"]]
        allow(client).to receive(:delete_multiple_objects).and_return(double(body: { 'Errors' => errors }))

        expect(Sentry).to receive(:capture_message).with("Bulk delete errors", extra: { errors: })

        perform
      end
    end
  end
end
