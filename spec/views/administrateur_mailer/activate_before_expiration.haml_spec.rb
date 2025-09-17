# frozen_string_literal: true

describe 'administrateur_mailer/activate_before_expiration', type: :view do
  let(:subject_text) { 'Activation de votre compte' }
  let(:expiration_date) { Time.zone.parse('2025-01-01 10:00') }
  let(:token) { 'reset-token' }
  let(:activate_url) { "https://example.test/activate/#{token}" }

  before do
    assign(:subject, subject_text)
    assign(:expiration_date, expiration_date)
    assign(:reset_password_token, token)

    allow(Current).to receive(:application_name).and_return(APPLICATION_NAME)
    allow(view).to receive(:users_activate_url).with(token: token).and_return(activate_url)

    render
  end

  it 'renders activation instructions with the activation link' do
    expect(rendered).to include('Bonjour')
    expect(rendered).to include(activate_url)
  end
end
