# frozen_string_literal: true

require 'rails_helper'

describe 'administrateur_mailer/activate_before_expiration', type: :view do
  let(:token) { 'reset-token' }
  let(:expiration_date) { Time.zone.local(2024, 7, 10) }

  before do
    assign(:subject, 'Activation requise')
    assign(:reset_password_token, token)
    assign(:expiration_date, expiration_date)
  end

  it 'renders the activation notice' do
    render template: 'administrateur_mailer/activate_before_expiration'

    expect(rendered).to include(users_activate_url(token: token))
  end
end
