# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe BackfillNaf2025Task do
    let(:procedure) { create(:procedure) }
    let(:task) { described_class.new }

    def fixture_file(filename) = Rails.root.join('spec/fixtures/files/api_entreprise', filename).read

    describe "#collection" do
      let!(:etablissement_without_naf2025) do
        create(:etablissement, dossier: create(:dossier, procedure:), naf_2025: nil)
      end

      let!(:etablissement_with_naf2025) do
        create(:etablissement, dossier: create(:dossier, procedure:), naf_2025: "84.11")
      end

      let!(:etablissement_without_siret) do
        e = build(:etablissement, dossier: create(:dossier, procedure:), naf_2025: nil, siret: nil)
        e.save!(validate: false)
        e
      end

      it "includes only etablissements with nil naf_2025 and non-nil siret" do
        expect(task.collection).to contain_exactly(etablissement_without_naf2025)
      end
    end

    describe "#process" do
      let(:dossier) { create(:dossier, :en_construction, procedure:) }
      let!(:etablissement) { create(:etablissement, dossier:, naf_2025: nil) }

      before do
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/insee\/sirene\/etablissements\/#{etablissement.siret}/)
          .to_return(body: fixture_file('etablissements.json'), status: 200)
      end

      it "updates all etablissement data from API response (not just naf_2025)" do
        task.process(etablissement)

        etablissement.reload
        expect(etablissement.naf_2025).to eq("84.11")
        expect(etablissement.libelle_naf_2025).to eq("Administration publique générale")
        expect(etablissement.naf).to eq("8411Z")
        expect(etablissement.entreprise_raison_sociale).to eq("DIRECTION INTERMINISTERIELLE DU NUMERIQUE")
        expect(etablissement.entreprise_siren).to eq("130025265")
      end

      it "does not touch updated_at on etablissement or dossier" do
        etablissement_updated_at = etablissement.updated_at
        dossier_updated_at = dossier.updated_at

        task.process(etablissement)

        expect(etablissement.reload.updated_at).to eq(etablissement_updated_at)
        expect(dossier.reload.updated_at).to eq(dossier_updated_at)
      end

      context "when API returns a failure" do
        before do
          stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/insee\/sirene\/etablissements\/#{etablissement.siret}/)
            .to_return(body: '{"errors":[{"code":"503","title":"Service unavailable"}]}', status: 503)
        end

        it "does not update and does not raise" do
          expect { task.process(etablissement) }.not_to raise_error
          expect(etablissement.reload.naf_2025).to be_nil
        end
      end

      context "when an exception is raised" do
        before do
          allow(APIEntreprise::EtablissementAdapter).to receive(:new).and_raise(StandardError, "boom")
        end

        it "logs to Rails and reports to Sentry" do
          expect(Rails.logger).to receive(:error).with(/BackfillNaf2025Task: #{etablissement.id}: boom/)
          expect(Sentry).to receive(:capture_exception)
          task.process(etablissement)
        end
      end

      context "when etablissement has no procedure (orphan)" do
        let!(:orphan_etablissement) do
          e = create(:etablissement, naf_2025: nil)
          e.update_column(:dossier_id, nil)
          e
        end

        it "skips without error" do
          expect { task.process(orphan_etablissement) }.not_to raise_error
          expect(orphan_etablissement.reload.naf_2025).to be_nil
        end
      end
    end
  end
end
