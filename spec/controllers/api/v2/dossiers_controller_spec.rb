# frozen_string_literal: true

describe API::V2::DossiersController do
  let(:dossier) { create(:dossier, :accepte, :with_attestation_acceptation) }
  let(:sgid) { dossier.to_sgid(expires_in: 1.hour, for: 'api_v2') }

  describe 'fetch pdf' do
    subject { get :pdf, params: { id: sgid } }

    it 'should get' do
      expect(subject.status).to eq(200)
      expect(subject.body).not_to be_nil
    end

    context 'error' do
      let(:sgid) { 'yolo' }

      it 'should error' do
        expect(subject.status).to eq(401)
      end
    end
  end

  describe 'fetch geojson' do
    subject { get :geojson, params: { id: sgid } }

    it 'should get' do
      expect(subject.status).to eq(200)
      expect(subject.body).not_to be_nil
    end

    context 'error' do
      let(:sgid) { 'yolo' }

      it 'should error' do
        expect(subject.status).to eq(401)
      end
    end

    context 'with several carte champs' do
      let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :carte }, { type: :carte }, { type: :carte }]) }
      let(:dossier) { create(:dossier, :accepte, :with_populated_champs, procedure:) }

      before do
        dossier.champ_data.each { _1.update(geo_areas: [build(:geo_area, :selection_utilisateur, :polygon)]) }
      end

      it 'loads every geo_area in a single query' do
        sgid # sign the dossier before counting

        count = 0
        callback = lambda { |*args| count += 1 if args.last[:sql].include?('geo_areas') }

        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { subject }

        expect(subject.status).to eq(200)
        expect(JSON.parse(subject.body)['features'].size).to eq(3)
        expect(count).to eq(1)
      end
    end
  end
end
