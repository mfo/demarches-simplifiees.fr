# frozen_string_literal: true

describe 'administrateurs/_main_navigation.html.haml', type: :view do
  let(:groupe_gestionnaire) { build_stubbed(:groupe_gestionnaire) }
  let(:administrateur) { build_stubbed(:administrateur, groupe_gestionnaire: groupe_gestionnaire) }

  before do
    allow(Rails.application.config).to receive(:ds_zonage_enabled).and_return(false)
    allow(view).to receive(:admin_procedures_path).and_return('/admin/procedures')
    allow(view).to receive(:admin_groupe_gestionnaire_path).and_return('/admin/groupe')
    allow(view).to receive(:current_administrateur).and_return(administrateur)
    allow(view).to receive(:current_page?).and_return(false)

    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render).with(instance_of(MainNavigation::AnnouncesLinkComponent)).and_return('')

    render partial: 'administrateurs/main_navigation'
  end

  it 'renders main navigation links' do
    expect(rendered).to include('Mes démarches')
    expect(rendered).to include('/admin/procedures')
  end
end
