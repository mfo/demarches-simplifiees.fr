# frozen_string_literal: true

describe 'administrateur_mailer/activate_before_expiration', type: :view do
  let(:subject_text) { 'Activation du compte' }
  let(:expiration_date) { Time.zone.parse('2024-05-01') }
  let(:reset_token) { 'reset-token' }

  before do
    Current.application_name = 'Démarches Simplifiées'
    assign(:subject, subject_text)
    assign(:expiration_date, expiration_date)
    assign(:reset_password_token, reset_token)
  end

  after do
    Current.reset
  end

  it 'renders the activation link' do
    render

    expect(rendered).to include(users_activate_url(token: reset_token))
  end
end
