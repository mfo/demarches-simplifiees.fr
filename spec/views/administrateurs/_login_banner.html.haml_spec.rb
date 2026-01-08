# frozen_string_literal: true

describe 'administrateurs/_login_banner', type: :view do
  it 'renders the sign out link' do
    render

    expect(rendered).to include('/administrateurs/sign_out')
    expect(rendered).to include('Se déconnecter')
  end
end
