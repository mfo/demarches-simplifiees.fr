# frozen_string_literal: true

RSpec.describe Cron::PurgeUnattachedBlobsJob, type: :job do
  describe 'perform' do
    subject { described_class.perform_now }

    # unattached, within the created_at window
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(io: StringIO.new("data"), filename: "data.txt", content_type: "text/plain").tap do |b|
        b.update_column(:created_at, 3.days.ago)
      end
    end

    before { blob }

    context 'when the blob has not been soft-deleted' do
      it 'enqueues a purge' do
        expect { subject }.to have_enqueued_job(DelayedPurgeJob)
      end
    end

    context 'when the blob has already been soft-deleted' do
      before { blob.update_column(:soft_delete_at, 1.hour.ago) }

      it 'does not enqueue a purge' do
        expect { subject }.not_to have_enqueued_job(DelayedPurgeJob)
      end
    end
  end
end
