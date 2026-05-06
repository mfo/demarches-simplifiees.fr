# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260427backfillVirusScanBlobsTask do
    describe '#collection' do
      it 'returns a batch enumerator scoped to pending blobs' do
        collection = described_class.new.collection
        expect(collection).to be_a(ActiveRecord::Batches::BatchEnumerator)
        expect(collection.relation.where_clause.to_h).to include("virus_scan_result" => ActiveStorage::VirusScanner::PENDING)
      end
    end

    describe '#process' do
      let(:dossier) { create(:dossier) }

      let!(:pending_blob) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("pending"), filename: "p.txt", content_type: "text/plain").tap do |b|
          b.update_columns(virus_scan_result: ActiveStorage::VirusScanner::PENDING)
        end
      end

      let!(:safe_blob) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("safe"), filename: "s.txt", content_type: "text/plain").tap do |b|
          b.update_columns(virus_scan_result: ActiveStorage::VirusScanner::SAFE)
        end
      end

      let!(:already_processed_blob) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("done"), filename: "d.txt", content_type: "text/plain").tap do |b|
          b.update_columns(
            virus_scan_result: ActiveStorage::VirusScanner::PENDING,
            metadata: b.metadata.merge("processed" => true)
          )
        end
      end

      let!(:variant_blob) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("variant"), filename: "v.txt", content_type: "text/plain").tap do |b|
          b.update_columns(virus_scan_result: ActiveStorage::VirusScanner::PENDING)
          parent_blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("parent"), filename: "parent.txt", content_type: "text/plain")
          parent_attachment = ActiveStorage::Attachment.create!(name: "piece_justificative_file", record: dossier, blob: parent_blob)
          ActiveStorage::Attachment.create!(name: "variant_medium", record: parent_attachment, blob: b)
        end
      end

      let!(:preview_image_blob) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("preview"), filename: "pr.txt", content_type: "text/plain").tap do |b|
          b.update_columns(virus_scan_result: ActiveStorage::VirusScanner::PENDING)
          ActiveStorage::Attachment.create!(name: "preview_image", record: dossier, blob: b)
        end
      end

      let!(:regular_attached_blob) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("regular"), filename: "r.txt", content_type: "text/plain").tap do |b|
          b.update_columns(virus_scan_result: ActiveStorage::VirusScanner::PENDING)
          ActiveStorage::Attachment.create!(name: "piece_justificative_file", record: dossier, blob: b)
        end
      end

      # Le batch reçu par process est déjà filtré sur pending par collection
      let(:batch) do
        ActiveStorage::Blob.where(id: [
          pending_blob.id, already_processed_blob.id,
          variant_blob.id, preview_image_blob.id, regular_attached_blob.id,
        ])
      end

      it 'enqueues for pending orphan blobs' do
        expect { described_class.new.process(batch) }
          .to have_enqueued_job(BlobProcessorJob).with(pending_blob).exactly(:once)
      end

      it 'enqueues for pending regularly attached blobs' do
        expect { described_class.new.process(batch) }
          .to have_enqueued_job(BlobProcessorJob).with(regular_attached_blob).exactly(:once)
      end

      it 'skips already processed blobs' do
        expect { described_class.new.process(batch) }
          .not_to have_enqueued_job(BlobProcessorJob).with(already_processed_blob)
      end

      it 'skips variant blobs (record_type: ActiveStorage::Attachment)' do
        expect { described_class.new.process(batch) }
          .not_to have_enqueued_job(BlobProcessorJob).with(variant_blob)
      end

      it 'skips preview image blobs' do
        expect { described_class.new.process(batch) }
          .not_to have_enqueued_job(BlobProcessorJob).with(preview_image_blob)
      end
    end
  end
end
