# frozen_string_literal: true

describe 'administrateur_mailer/notify_service_without_siret', type: :view do
  let(:procedures_url) { 'https://example.test/admin/procedures' }

  before do
    allow(Current).to receive(:application_name).and_return(APPLICATION_NAME)
    allow(view).to receive(:admin_procedures_url).and_return(procedures_url)

    render
  end

  it 'includes a link to the admin procedures page' do
    expect(rendered).to include(procedures_url)
  end
end
