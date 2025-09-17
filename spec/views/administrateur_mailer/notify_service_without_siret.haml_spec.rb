# frozen_string_literal: true

require 'rails_helper'

describe 'administrateur_mailer/notify_service_without_siret', type: :view do
  before do
    Current.application_name = 'Démarches Simplifiées'
  end

  after { Current.reset_all }

  it 'renders the reminder email' do
    render template: 'administrateur_mailer/notify_service_without_siret'

    expect(rendered).to include(Current.application_name)
    expect(rendered).to include(admin_procedures_url)
  end
end
