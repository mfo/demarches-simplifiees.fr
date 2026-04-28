# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260427backfillVirusScanBlobsTask do
    describe '#collection' do
      let!(:pending) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("pending"), filename: "pending.txt", content_type: "text/plain").tap do |blob|
          blob.update_columns(virus_scan_result: ActiveStorage::VirusScanner::PENDING)
        end
      end

      let!(:safe) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("safe"), filename: "safe.txt", content_type: "text/plain").tap do |blob|
          blob.update_columns(virus_scan_result: ActiveStorage::VirusScanner::SAFE)
        end
      end

      subject(:collection) { described_class.new.collection }

      it 'includes pending blobs' do
        expect(collection).to include(pending)
      end

      it 'excludes safe blobs' do
        expect(collection).not_to include(safe)
      end
    end

    describe '#process' do
      let!(:blob) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("data"), filename: "file.txt", content_type: "text/plain").tap do |blob|
          blob.update_columns(virus_scan_result: ActiveStorage::VirusScanner::PENDING)
        end
      end

      let!(:already_processed) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("done"), filename: "done.txt", content_type: "text/plain").tap do |blob|
          blob.update_columns(
            virus_scan_result: ActiveStorage::VirusScanner::PENDING,
            metadata: blob.metadata.merge("processed" => true)
          )
        end
      end

      it 'enqueues a BlobProcessorJob' do
        expect { described_class.new.process(blob) }
          .to have_enqueued_job(BlobProcessorJob).with(blob)
      end

      it 'skips already processed blobs' do
        expect { described_class.new.process(already_processed) }
          .not_to have_enqueued_job(BlobProcessorJob)
      end
    end
  end
end
