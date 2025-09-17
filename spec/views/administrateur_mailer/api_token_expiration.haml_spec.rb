# frozen_string_literal: true

describe 'administrateur_mailer/api_token_expiration', type: :view do
  let(:subject_text) { 'Expiration de jeton' }
  let(:token) { double('Token', prefix: 'ABC123') }
  let(:profile_url) { 'https://example.test/profil' }

  before do
    assign(:subject, subject_text)
    assign(:tokens, [token])

    allow(Current).to receive(:application_name).and_return(APPLICATION_NAME)
    allow(view).to receive(:profil_url).and_return(profile_url)

    render
  end

  it 'mentions the token prefix and the profile link' do
    expect(rendered).to include(token.prefix)
    expect(rendered).to include(profile_url)
  end
end
