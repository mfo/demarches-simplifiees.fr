# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260129destroyOrphanEtablissementsTask do
    describe "#collection" do
      subject(:collection) { described_class.new.collection }

      let!(:orphan_etablissement) { create(:etablissement, dossier: nil) }
      let!(:etablissement_with_dossier) { create(:etablissement, dossier: create(:dossier)) }
      let!(:etablissement_with_champ) do
        procedure = create(:procedure, types_de_champ_public: [{ type: :siret }])
        dossier = create(:dossier, procedure:)
        etablissement = create(:etablissement, dossier: nil)
        dossier.champs.first.update!(etablissement:)
        etablissement
      end

      it "returns only orphan etablissements" do
        expect(collection).to contain_exactly(orphan_etablissement)
      end
    end

    describe "#process" do
      subject(:process) { described_class.new.process(etablissement) }

      let(:etablissement) { create(:etablissement, dossier: nil) }

      it "destroys the etablissement" do
        expect { process }.to change { Etablissement.exists?(etablissement.id) }.from(true).to(false)
      end
    end
  end
end
