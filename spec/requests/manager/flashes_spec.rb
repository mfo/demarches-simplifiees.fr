# frozen_string_literal: true

describe 'Manager flash messages', type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:groupe_gestionnaire) { create(:groupe_gestionnaire) }

  before { login_as super_admin, scope: :super_admin }

  it 'renders the flash value as text' do
    post add_gestionnaire_manager_groupe_gestionnaire_path(groupe_gestionnaire),
      params: { emails: '<b>bold</b>@mail.com' }
    follow_redirect!

    expect(response.body).to include('&lt;b&gt;bold&lt;/b&gt;@mail.com')
    expect(response.body).not_to include('<b>bold</b>@mail.com')
  end
end
