# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260722updateProcedureEstimatedDossiersCountTask do
    describe "#process" do
      subject(:process) { described_class.process }

      let(:procedure) { create(:procedure, :published) }

      before do
        create(:dossier, :en_instruction, procedure:)
        create(:dossier, :en_construction, procedure:, hidden_by_reason: nil)
        create(:dossier, :en_construction, procedure:, hidden_by_reason: :user_request)
        create(:deleted_dossier, state: :accepte, procedure:)
        create(:deleted_dossier, dossier_id: 2222, state: :en_construction, procedure:, reason: :expired)
        create(:deleted_dossier, dossier_id: 3333, state: :en_construction, procedure:, reason: :user_request)
      end

      it "updates estimated_dossiers_count" do
        freeze_time do
          process

          procedure.reload

          expect(procedure.estimated_dossiers_count).to eq(4)
          expect(procedure.dossiers_count_computed_at).to eq(Time.zone.now)
        end
      end
    end
  end
end
