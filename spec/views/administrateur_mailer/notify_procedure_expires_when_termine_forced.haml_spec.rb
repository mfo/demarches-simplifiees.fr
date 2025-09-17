# frozen_string_literal: true

describe 'administrateur_mailer/notify_procedure_expires_when_termine_forced', type: :view do
  let(:procedure) { build(:procedure, libelle: 'Ma démarche RGPD') }
  let(:archive_link) { 'https://www.example.com/archives' }

  before do
    Current.application_name = 'Démarches Simplifiées'
    assign(:procedure, procedure)
    allow(view).to receive(:admin_procedures_archived_url).with(procedure).and_return(archive_link)
  end

  after do
    Current.reset
  end

  it 'mentions the automatic deletion activation' do
    render

    expect(rendered).to include(procedure.libelle)
    expect(rendered).to include(archive_link)
  end
end
