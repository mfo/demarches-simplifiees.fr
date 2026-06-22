# frozen_string_literal: true

describe Manager::TeamAccountsController, type: :controller do
  let(:super_admin) { create(:super_admin, :with_otp) }
  before { sign_in super_admin }

  render_views

  describe 'GET #index' do
    let!(:team_account) { create(:administrateur, user: create(:user, team_account: true)) }

    it 'liste les comptes équipe' do
      get :index

      expect(response).to have_http_status(:ok)
    end
  end
end
