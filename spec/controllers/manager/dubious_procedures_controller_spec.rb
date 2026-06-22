# frozen_string_literal: true

describe Manager::DubiousProceduresController, type: :controller do
  let(:super_admin) { create(:super_admin, :with_otp) }
  before { sign_in super_admin }

  render_views

  describe 'GET #index' do
    it 'affiche la liste des procédures douteuses' do
      get :index

      expect(response).to have_http_status(:ok)
    end
  end
end
