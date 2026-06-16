# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260616backfillRNAExternalIdTask do
    describe "#process" do
      subject(:process) { described_class.process }

      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :rna }, { type: :rna }, { type: :rna }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }

      let!(:legacy_champ) { dossier.champs[0].tap { it.update_columns(value: 'W173847273', external_id: nil) } }
      let!(:already_migrated_champ) { dossier.champs[1].tap { it.update_columns(value: 'W173847273', external_id: 'W999999999') } }
      let!(:blank_champ) { dossier.champs[2].tap { it.update_columns(value: nil, external_id: nil) } }

      it "recopie value dans external_id pour les anciens champs" do
        expect { process }.to change { legacy_champ.reload.external_id }.from(nil).to('W173847273')
      end

      it "n'écrase pas un external_id déjà renseigné" do
        expect { process }.not_to change { already_migrated_champ.reload.external_id }.from('W999999999')
      end

      it "laisse external_id nul quand value est absent" do
        expect { process }.not_to change { blank_champ.reload.external_id }.from(nil)
      end
    end
  end
end
