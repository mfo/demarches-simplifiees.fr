# frozen_string_literal: true

describe 'administrateurs/_login_banner.html.haml', type: :view do
  it 'links to the sign out path' do
    render partial: 'administrateurs/login_banner'

    expect(rendered).to include('/administrateurs/sign_out')
  end
end
