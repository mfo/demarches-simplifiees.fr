# frozen_string_literal: true

# The feature contributes a block to the manager's user page through
# ViewExtensionHelper. The host spec knows nothing about it, so the wiring is
# covered here.
describe Manager::UsersController, type: :controller do
  let(:super_admin) { create(:super_admin) }

  before { sign_in super_admin }

  describe '#show' do
    render_views

    before { get :show, params: { id: user.id } }

    context 'when the user is a gestionnaire' do
      let(:gestionnaire) { create(:gestionnaire) }
      let(:user) { gestionnaire.user }

      it 'links to their gestionnaire account' do
        expect(response.body).to include(manager_gestionnaire_path(gestionnaire))
      end
    end

    context 'when the user is not a gestionnaire' do
      let(:user) { create(:user) }

      it { expect(response.body).to include('Pas gestionnaire !') }
    end
  end
end
