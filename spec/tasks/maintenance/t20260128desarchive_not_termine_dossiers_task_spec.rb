# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260128desarchiveNotTermineDossiersTask do
    describe "#collection" do
      subject(:collection) { task.collection }

      let(:task) { described_class.new.tap { _1.dossier_ids = dossier_ids } }

      let(:dossier_ids) { [dossier_archived_en_construction, dossier_archived_en_instruction, dossier_archived_accepte, dossier_not_archived].map(&:id).join(",") }

      let!(:dossier_archived_en_construction) { create(:dossier, :en_construction) }
      let!(:dossier_archived_en_instruction) { create(:dossier, :en_instruction) }
      let!(:dossier_archived_accepte) { create(:dossier, :accepte) }
      let!(:dossier_not_archived) { create(:dossier, :en_construction) }

      before do
        dossier_archived_en_construction.update_columns(archived: true)
        dossier_archived_en_instruction.update_columns(archived: true)
        dossier_archived_accepte.update_columns(archived: true)
      end

      it "includes only archived dossiers that are not termine among provided ids" do
        expect(collection).to include(dossier_archived_en_construction)
        expect(collection).to include(dossier_archived_en_instruction)
        expect(collection).not_to include(dossier_archived_accepte)
        expect(collection).not_to include(dossier_not_archived)
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(dossier) }

      let(:dossier) { create(:dossier, :en_construction) }

      before do
        dossier.update_columns(archived: true, archived_at: 1.day.ago, archived_by: "instructeur@example.com")
      end

      it "unarchives the dossier" do
        expect { subject }.to change { dossier.reload.archived }.from(true).to(false)
      end

      it "clears archived_at" do
        expect { subject }.to change { dossier.reload.archived_at }.to(nil)
      end

      it "clears archived_by" do
        expect { subject }.to change { dossier.reload.archived_by }.to(nil)
      end
    end
  end
end
