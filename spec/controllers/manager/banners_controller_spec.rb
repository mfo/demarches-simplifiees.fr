# frozen_string_literal: true

describe Manager::BannersController, type: :controller do
  let(:super_admin) { create(:super_admin, :with_otp) }
  before { sign_in super_admin }

  render_views

  describe 'GET #index' do
    let!(:banner) { Banner.create!(target: 'global', content: 'Message global') }

    it 'liste les bannières et le champ OTP de confirmation' do
      get :index

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Banner::TARGET_LABELS['global'])
      expect(response.body).to include('name="otp_attempt"')
    end
  end

  describe 'PATCH #update' do
    let(:banner) { Banner.create!(target: 'global', content: '') }
    let(:otp_attempt) { current_otp_for(super_admin) }

    subject { patch :update, params: { id: banner.id, banner: { content: 'Nouveau message' }, otp_attempt: otp_attempt } }

    it_behaves_like "a manager action gated by a fresh super-admin OTP" do
      let(:action_matcher) { change { banner.reload.content } }
      let(:replay_subject) do
        -> { patch :update, params: { id: banner.id, banner: { content: 'Autre message' }, otp_attempt: otp_attempt } }
      end
    end

    it 'publie en renseignant le contenu' do
      subject

      expect(banner.reload.content).to eq('Nouveau message')
      expect(banner).to be_active
    end

    it 'dépublie en vidant le contenu' do
      banner.update!(content: 'Ancien')

      patch :update, params: { id: banner.id, banner: { content: '' }, otp_attempt: current_otp_for(super_admin) }

      expect(banner.reload.content).to eq('')
      expect(banner).not_to be_active
    end
  end
end
