# frozen_string_literal: true

require 'rails_helper'

describe 'administrateur_mailer/notify_procedure_expires_when_termine_forced', type: :view do
  let(:procedure) { create(:procedure, libelle: 'Démarche Test') }

  before do
    assign(:procedure, procedure)
    Current.application_name = 'Démarches Simplifiées'
  end

  after { Current.reset_all }

  it 'renders the notification email' do
    render template: 'administrateur_mailer/notify_procedure_expires_when_termine_forced'

    expect(rendered).to include(procedure.libelle)
    expect(rendered).to include(admin_procedures_archived_url(procedure))
  end
end
