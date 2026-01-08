# frozen_string_literal: true

describe 'administrateur_mailer/notify_service_without_siret', type: :view do
  let(:procedures_url) { 'https://www.example.com/admin/procedures' }

  before do
    Current.application_name = 'Démarches Simplifiées'
    allow(view).to receive(:admin_procedures_url).and_return(procedures_url)
  end

  after do
    Current.reset
  end

  it 'renders the reminder with the procedures link' do
    render

    expect(rendered).to include(Current.application_name)
    expect(rendered).to include(procedures_url)
  end
end
