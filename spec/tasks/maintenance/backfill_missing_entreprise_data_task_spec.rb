# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe BackfillMissingEntrepriseDataTask do
    let(:procedure) { create(:procedure) }
    let(:task) { described_class.new }

    let(:dossier_to_repair) { create(:dossier, :en_construction, procedure:) }
    let!(:etablissement_to_repair) do
      create(:etablissement,
        dossier: dossier_to_repair,
        siret: "44011762001530",
        entreprise_siren: nil)
    end

    let(:dossier_already_valid) { create(:dossier, :en_construction, procedure:) }
    let!(:etablissement_already_valid) do
      create(:etablissement,
        dossier: dossier_already_valid,
        siret: "44011762001531",
        entreprise_siren: "440117620")
    end

    describe "#collection" do
      it "includes etablissement without entreprise_siren" do
        collection = task.collection
        expect(collection).to contain_exactly(etablissement_to_repair)
      end
    end

    describe "#process" do
      it "calls perform_later_fetch_jobs to enqueue all API Entreprise jobs" do
        allow(task).to receive(:max_wait).and_return(0)

        expect(APIEntrepriseService).to receive(:perform_later_fetch_jobs).with(
          etablissement_to_repair,
          procedure.id,
          nil,
          wait: 0.seconds
        )

        task.process(etablissement_to_repair)
      end
    end
  end
end
