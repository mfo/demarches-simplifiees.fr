# frozen_string_literal: true

describe Champs::CarteController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :carte }]) }
  let(:dossier) { create(:dossier, user: user, procedure: procedure) }
  let(:champ) { dossier.champs.first }
  let(:feature) { attributes_for(:geo_area, :polygon) }
  let!(:geo_area) { create(:geo_area, :selection_utilisateur, :polygon, champ: champ) }

  before do
    sign_in user
    request.accept = "application/json"
    request.content_type = "application/json"
  end

  context 'when dossier is en_construction' do
    before do
      champ.geo_areas.reset
      dossier.passer_en_construction!
    end

    describe 'DELETE #destroy' do
      it 'finds the cloned geo_area by source_id and deletes it' do
        expect {
          delete :destroy, params: {
            dossier_id: champ.dossier_id,
            stable_id: champ.stable_id,
            id: geo_area.id,
          }
        }.to change { GeoArea.count }.by(0) # +1 clone, -1 delete = net 0
        expect(response).to have_http_status(:no_content)
      end
    end

    describe 'PATCH #update' do
      it 'finds the cloned geo_area by source_id and returns the new id' do
        patch :update, params: {
          dossier_id: champ.dossier_id,
          stable_id: champ.stable_id,
          id: geo_area.id,
          feature: feature,
        }
        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['geo_area_id']).to be_present
        expect(body['geo_area_id']).not_to eq(geo_area.id)
      end
    end

    describe 'POST #create' do
      it 'creates a new geo_area on the buffer champ' do
        expect {
          post :create, params: {
            dossier_id: champ.dossier_id,
            stable_id: champ.stable_id,
            feature: feature,
            source: GeoArea.sources.fetch(:selection_utilisateur),
          }
        }.to change { GeoArea.count }.by(2) # 1 clone + 1 new
        expect(response).to have_http_status(:created)
        expect(response.parsed_body['feature']).to be_present
      end
    end

    describe 'self-healing across multiple operations' do
      let!(:geo_area2) { create(:geo_area, :selection_utilisateur, :polygon, champ: champ) }

      before { champ.geo_areas.reset }

      it 'each operation resolves its own ID via source_id' do
        # First: delete geo_area by source_id
        delete :destroy, params: {
          dossier_id: champ.dossier_id,
          stable_id: champ.stable_id,
          id: geo_area.id,
        }
        expect(response).to have_http_status(:no_content)

        # Second: update geo_area2 by source_id, get new id back
        patch :update, params: {
          dossier_id: champ.dossier_id,
          stable_id: champ.stable_id,
          id: geo_area2.id,
          feature: feature,
        }
        expect(response).to have_http_status(:ok)
        new_id = response.parsed_body['geo_area_id']

        # Third: use the new id directly
        patch :update, params: {
          dossier_id: champ.dossier_id,
          stable_id: champ.stable_id,
          id: new_id,
          feature: feature,
        }
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  context 'when dossier is brouillon' do
    describe 'DELETE #destroy' do
      it 'deletes directly' do
        expect {
          delete :destroy, params: {
            dossier_id: champ.dossier_id,
            stable_id: champ.stable_id,
            id: geo_area.id,
          }
        }.to change { GeoArea.count }.by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    describe 'PATCH #update' do
      it 'updates directly' do
        patch :update, params: {
          dossier_id: champ.dossier_id,
          stable_id: champ.stable_id,
          id: geo_area.id,
          feature: feature,
        }
        expect(response).to have_http_status(:no_content)
      end
    end

    describe 'POST #create' do
      it 'creates a new geo_area' do
        expect {
          post :create, params: {
            dossier_id: champ.dossier_id,
            stable_id: champ.stable_id,
            feature: feature,
            source: GeoArea.sources.fetch(:selection_utilisateur),
          }
        }.to change { GeoArea.count }.by(1)
        expect(response).to have_http_status(:created)
        expect(response.parsed_body['feature']).to be_present
      end
    end
  end
end
