# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260527BackfillNaf2025Task do
    let(:task) { described_class.new }
    let(:procedure) { create(:procedure) }

    describe "#collection" do
      empty_seeds Etablissement

      let!(:etablissement_without_naf_2025) do
        create(:etablissement, dossier: create(:dossier, :en_construction, procedure:), siret: "44011762001530", naf_2025: nil)
      end
      let!(:duplicate_same_siret) do
        create(:etablissement, dossier: create(:dossier, :en_construction, procedure:), siret: "44011762001530", naf_2025: nil)
      end
      let!(:etablissement_already_filled) do
        create(:etablissement, dossier: create(:dossier, :en_construction, procedure:), siret: "44011762001531", naf_2025: "84.11", libelle_naf_2025: "Administration publique générale")
      end

      it "returns etablissements with nil naf_2025" do
        expect(task.collection).to contain_exactly(etablissement_without_naf_2025, duplicate_same_siret)
      end
    end

    describe "#process" do
      let(:siret) { "44011762001530" }
      let(:dossier) { create(:dossier, :en_construction, procedure:) }
      let!(:etablissement) { create(:etablissement, dossier:, siret:, naf_2025: nil) }

      context "when API returns naf_2025 data" do
        let(:api_params) { { naf_2025: "62.01", libelle_naf_2025: "Programmation informatique" } }

        before do
          allow(APIEntreprise::EtablissementAdapter).to receive(:new)
            .with(siret, procedure.id)
            .and_return(instance_double(APIEntreprise::EtablissementAdapter, to_params: Dry::Monads::Success(api_params)))
        end

        it "updates the etablissement with naf_2025 data" do
          task.process(etablissement)
          etablissement.reload
          expect(etablissement.naf_2025).to eq("62.01")
          expect(etablissement.libelle_naf_2025).to eq("Programmation informatique")
        end

        context "with duplicate siret across multiple etablissements" do
          let(:other_dossier) { create(:dossier, :en_construction, procedure:) }
          let!(:duplicate_etablissement) { create(:etablissement, dossier: other_dossier, siret:, naf_2025: nil) }

          it "updates all etablissements sharing the same siret" do
            task.process(etablissement)
            expect(duplicate_etablissement.reload.naf_2025).to eq("62.01")
            expect(duplicate_etablissement.libelle_naf_2025).to eq("Programmation informatique")
          end
        end
      end

      context "when no procedure is found (orphan etablissement)" do
        let!(:etablissement) { create(:etablissement, dossier: nil, siret:, naf_2025: nil) }

        it "skips without error" do
          expect(APIEntreprise::EtablissementAdapter).not_to receive(:new)
          task.process(etablissement)
        end
      end

      context "when naf_2025 already backfilled by a previous duplicate" do
        let!(:etablissement) { create(:etablissement, dossier:, siret:, naf_2025: "62.01", libelle_naf_2025: "Programmation informatique") }

        it "skips without calling API" do
          expect(APIEntreprise::EtablissementAdapter).not_to receive(:new)
          task.process(etablissement)
        end
      end

      context "when API returns a failure" do
        before do
          allow(APIEntreprise::EtablissementAdapter).to receive(:new)
            .with(siret, procedure.id)
            .and_return(instance_double(APIEntreprise::EtablissementAdapter, to_params: Dry::Monads::Failure(type: :server_error, code: 500, retryable: true, raw_response: nil)))
        end

        it "leaves naf_2025 nil" do
          task.process(etablissement)
          expect(etablissement.reload.naf_2025).to be_nil
        end
      end

      context "when an exception is raised" do
        before do
          allow(APIEntreprise::EtablissementAdapter).to receive(:new).and_raise(StandardError, "boom")
          allow(Sentry).to receive(:capture_exception)
        end

        it "captures the exception in Sentry and continues" do
          expect { task.process(etablissement) }.not_to raise_error
          expect(Sentry).to have_received(:capture_exception)
        end
      end
    end
  end
end
