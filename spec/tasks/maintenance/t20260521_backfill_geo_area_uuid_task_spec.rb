# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260521BackfillGeoAreaUuidTask do
    describe "#process" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :carte }]) }
      let(:dossier) { create(:dossier, procedure:) }
      let(:main_champ) { dossier.champs.first }
      let(:main_geo_area) do
        ga = create(:geo_area, :selection_utilisateur, :polygon, champ: main_champ)
        ga.update_column(:uuid, nil)
        ga.reload
      end

      subject(:process) { described_class.new.process(main_geo_area) }

      it 'assigns a uuid to a main stream geo_area that has none' do
        expect { process }.to change { main_geo_area.reload.uuid }.from(nil).to(a_kind_of(String))
      end

      context 'when the main stream geo_area already has a uuid' do
        let(:existing_uuid) { SecureRandom.uuid }
        before { main_geo_area.update_column(:uuid, existing_uuid) }

        it 'keeps the existing uuid' do
          expect { process }.not_to change { main_geo_area.reload.uuid }
        end
      end

      context 'when a matching geo_area exists in another stream' do
        let(:buffer_champ) do
          champ = main_champ.dup
          champ.stream = Champ::USER_BUFFER_STREAM
          champ.save!(validate: false)
          champ
        end
        let!(:buffer_geo_area) { create(:geo_area, :selection_utilisateur, :polygon, champ: buffer_champ) }

        it 'propagates the same uuid to the matching geo_area' do
          process
          expect(buffer_geo_area.reload.uuid).to eq(main_geo_area.reload.uuid)
        end
      end

      context 'when a geo_area in another stream has a different geometry' do
        let(:buffer_champ) do
          champ = main_champ.dup
          champ.stream = Champ::USER_BUFFER_STREAM
          champ.save!(validate: false)
          champ
        end
        let!(:buffer_geo_area) { create(:geo_area, :selection_utilisateur, :point, champ: buffer_champ) }

        it 'does not update its uuid' do
          expect(buffer_geo_area.reload.uuid).to be_nil
        end
      end
    end
  end
end
