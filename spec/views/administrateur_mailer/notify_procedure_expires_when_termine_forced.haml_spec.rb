# frozen_string_literal: true

describe 'administrateur_mailer/notify_procedure_expires_when_termine_forced', type: :view do
  let(:procedure) { create(:procedure, libelle: 'Procédure test') }
  let(:archive_url) { 'https://example.test/admin/procedures/archives' }

  before do
    assign(:procedure, procedure)

    allow(Current).to receive(:application_name).and_return(APPLICATION_NAME)
    allow(view).to receive(:admin_procedures_archived_url).with(procedure).and_return(archive_url)

    render
  end

  it 'displays the procedure name and archive link' do
    expect(rendered).to include(procedure.libelle)
    expect(rendered).to include(archive_url)
  end
end
