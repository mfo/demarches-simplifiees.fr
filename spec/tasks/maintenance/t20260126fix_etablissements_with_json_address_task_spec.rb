# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260126fixEtablissementsWithJSONAddressTask do
    describe "#collection" do
      subject(:collection) { described_class.new.collection }

      let!(:etablissement_with_json_address) do
        create(:etablissement, adresse: '{complement: "Champ Fleuri", numero_voie: "45"}')
      end

      let!(:etablissement_with_normal_address) do
        create(:etablissement, adresse: "DIRECTION INTERMINISTERIELLE\r\n22 RUE DE LA PAIX\r\n75016 PARIS")
      end

      it "returns only etablissements with JSON-like addresses" do
        expect(collection).to include(etablissement_with_json_address)
        expect(collection).not_to include(etablissement_with_normal_address)
      end
    end

    describe "#process" do
      subject(:process) { described_class.new.process(etablissement) }

      let(:procedure) { create(:procedure) }
      let(:dossier) { create(:dossier, :en_construction, procedure:) }
      let(:etablissement) { create(:etablissement, dossier:, adresse: '{complement: "test"}') }

      it "enqueues EtablissementJob" do
        expect { process }.to have_enqueued_job(APIEntreprise::EtablissementJob)
          .with(etablissement.id, procedure.id)
      end

      context "when dossier is termine" do
        let(:dossier) { create(:dossier, :accepte, procedure:) }

        it "does not enqueue any job" do
          expect { process }.not_to have_enqueued_job(APIEntreprise::EtablissementJob)
        end
      end
    end
  end
end
