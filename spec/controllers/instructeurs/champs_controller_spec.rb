# frozen_string_literal: true

describe Instructeurs::ChampsController, type: :controller do
  let(:instructeur) { create(:instructeur) }
  let(:instructeurs) { [instructeur] }
  let(:types_de_champ_public) { [{ type: :piece_justificative, nature: 'RIB' }] }
  let(:procedure) { create(:procedure, instructeurs:, types_de_champ_public:) }
  let(:dossier) { create(:dossier, :en_construction, procedure:) }
  let(:champ) { dossier.champs.first }

  before { sign_in(instructeur.user) }

  describe '#edit' do
    subject { get :edit, params: { dossier_id: dossier.id, public_id: champ.public_id } }

    it do
      is_expected.to have_http_status(:ok)
      # simple check to ensure no duplicate champs are created
      expect(Champ.where(stable_id: champ.stable_id, row_id: champ.row_id).count).to eq(1)
    end

    context 'when the instructeur is not assigned to the dossier' do
      let(:instructeurs) { [] }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
