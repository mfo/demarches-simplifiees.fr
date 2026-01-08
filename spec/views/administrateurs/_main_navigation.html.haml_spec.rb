# frozen_string_literal: true

describe 'administrateurs/_main_navigation', type: :view do
  let(:procedures_path) { '/admin/procedures' }
  let(:all_procedures_path) { '/admin/procedures/all' }
  let(:groupe_path) { '/admin/groupe' }
  let(:announces_html) { '<li class="announces-link"></li>'.html_safe }

  before do
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render).with(instance_of(MainNavigation::AnnouncesLinkComponent)).and_return(announces_html)
    allow(view).to receive(:admin_procedures_path).and_return(procedures_path)
    allow(view).to receive(:current_page?).and_return(false)
  end

  context 'when zonage is disabled and there is no gestionnaire group' do
    before do
      allow(Rails.application.config).to receive(:ds_zonage_enabled).and_return(false)
      allow(view).to receive(:current_administrateur).and_return(instance_double('Administrateur', groupe_gestionnaire_id: nil))
      allow(view).to receive(:current_page?).with(controller: 'administrateurs/procedures', action: :index).and_return(true)
    end

    it 'renders only the procedures link with announces entry' do
      render

      expect(rendered).to include(procedures_path)
      expect(rendered).not_to include('Toutes les démarches')
      expect(rendered).to include('announces-link')
    end
  end

  context 'when zonage is enabled and the administrateur has a gestionnaire group' do
    before do
      allow(Rails.application.config).to receive(:ds_zonage_enabled).and_return(true)
      allow(view).to receive(:current_administrateur).and_return(instance_double('Administrateur', groupe_gestionnaire_id: 12))
      allow(view).to receive(:all_admin_procedures_path).and_return(all_procedures_path)
      allow(view).to receive(:admin_groupe_gestionnaire_path).and_return(groupe_path)
    end

    it 'renders all navigation links' do
      render

      expect(rendered).to include(procedures_path)
      expect(rendered).to include(all_procedures_path)
      expect(rendered).to include(groupe_path)
    end
  end
end
