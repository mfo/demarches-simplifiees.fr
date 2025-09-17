# frozen_string_literal: true

require 'rails_helper'

describe 'administrateurs/main_navigation', type: :view do
  before do
    allow(Rails.application.config).to receive(:ds_zonage_enabled).and_return(true)
    current_admin = double(groupe_gestionnaire_id: 1, api_tokens: double(exists?: false))
    allow(view).to receive(:current_administrateur).and_return(current_admin)
    allow(view).to receive(:current_page?).and_return(false)
    allow(view).to receive(:instructeur_signed_in?).and_return(false)
    allow(view).to receive(:administrateur_signed_in?).and_return(true)
    allow(view).to receive(:expert_signed_in?).and_return(false)
  end

  it 'renders the navigation menu' do
    render partial: 'administrateurs/main_navigation'

    expect(rendered).to include('Mes démarches')
    expect(rendered).to include('Toutes les démarches')
    expect(rendered).to include('Mon groupe gestionnaire')
  end
end
