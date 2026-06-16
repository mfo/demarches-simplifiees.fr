# frozen_string_literal: true

RSpec.describe Attachment::PieceJustificativeService do
  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :piece_justificative }]) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first }

  let(:blob_1) { ActiveStorage::Blob.create_and_upload!(io: StringIO.new("file1"), filename: "file1.pdf", content_type: "application/pdf") }
  let(:blob_2) { ActiveStorage::Blob.create_and_upload!(io: StringIO.new("file2"), filename: "file2.pdf", content_type: "application/pdf") }

  describe '.attach_champ_pj' do
    context 'with sequential uploads' do
      it 'preserves all attachments' do
        described_class.attach_champ_pj(champ, blob_1.signed_id)
        described_class.attach_champ_pj(champ, blob_2.signed_id)

        expect(champ.reload.piece_justificative_file.count).to eq(2)
      end
    end

    context 'with concurrent uploads (simulated stale state)' do
      it 'preserves all attachments' do
        champ_a = Champ.find(champ.id)
        champ_b = Champ.find(champ.id)

        # Force-load the blobs association on both instances before either attaches.
        # This simulates two concurrent requests that both read blobs = [] at the same time.
        champ_a.piece_justificative_file.blobs.to_a
        champ_b.piece_justificative_file.blobs.to_a

        described_class.attach_champ_pj(champ_a, blob_1.signed_id)
        described_class.attach_champ_pj(champ_b, blob_2.signed_id)

        expect(champ.reload.piece_justificative_file.count).to eq(2)
      end
    end

    context 'with an OCR-compatible PJ (justificatif de domicile)' do
      let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :piece_justificative, nature: 'justificatif_domicile' }]) }

      it 'transitions the champ to waiting_for_job in the same transaction' do
        described_class.attach_champ_pj(champ, blob_1.signed_id)

        expect(champ.reload).to be_waiting_for_job
      end
    end

    context 'with a non-OCR PJ' do
      it 'leaves the champ idle' do
        described_class.attach_champ_pj(champ, blob_1.signed_id)

        expect(champ.reload).to be_idle
      end
    end
  end
end
