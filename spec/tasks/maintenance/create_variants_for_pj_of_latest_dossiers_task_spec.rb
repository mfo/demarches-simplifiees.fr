# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe CreateVariantsForPjOfLatestDossiersTask do
    describe "#process" do
      let(:procedure) { create(:procedure_with_dossiers, types_de_champ_public: [{ type: :piece_justificative, libelle: 'Justificatif de domicile', stable_id: 3 }]) }
      let(:dossier) { procedure.dossiers.first }
      let(:champ_pj) { dossier.champs.first }
      let(:attachment) { champ_pj.piece_justificative_file.attachments.first }
      let(:file_type) { '' }
      let(:task) { described_class.new.tap { _1.file_type = file_type } }

      before do
        champ_pj.piece_justificative_file.attach(file)

        dossier.update(
          depose_at: Date.new(2024, 05, 23),
          state: "en_construction"
        )
      end

      subject(:process) { task.process(dossier) }

      context "when pj is a classical format image" do
        let(:file) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }

        it "creates a variant" do
          expect(attachment.variant(resize_to_limit: [400, 400]).key).to be_nil
          expect { subject }.to change { ActiveStorage::VariantRecord.count }.by(1)
          expect(attachment.variant(resize_to_limit: [400, 400]).key).not_to be_nil
          expect(attachment.variant(resize_to_limit: [2000, 2000]).key).to be_nil
        end

        context "when file_type is 'pdf'" do
          let(:file_type) { 'pdf' }

          it "skips image attachments" do
            expect { subject }.not_to change { ActiveStorage::VariantRecord.count }
          end
        end
      end

      context "when pj is a rare format image" do
        let(:file) { fixture_file_upload('spec/fixtures/files/pencil.tiff', 'image/tiff') }

        it "creates two variants" do
          expect(attachment.variant(resize_to_limit: [400, 400]).key).to be_nil
          expect { subject }.to change { ActiveStorage::VariantRecord.count }.by(2)
          expect(attachment.variant(resize_to_limit: [400, 400]).key).not_to be_nil
          expect(attachment.variant(resize_to_limit: [2000, 2000]).key).not_to be_nil
        end
      end

      context "when pj is a pdf", :external_deps do
        let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }

        it "creates a representation" do
          expect { subject }.to change { ActiveStorage::VariantRecord.count }.by(1)
        end

        context "when file_type is 'image'" do
          let(:file_type) { 'image' }

          it "skips pdf attachments" do
            expect { subject }.not_to change { ActiveStorage::VariantRecord.count }
          end
        end
      end
    end
  end
end
