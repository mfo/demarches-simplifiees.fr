# frozen_string_literal: true

require 'rails_helper'

describe 'administrateurs/groups_header', type: :view do
  let(:procedure) { create(:procedure) }
  let(:groupe_instructeur) { create(:groupe_instructeur, procedure: procedure, label: 'Groupe Bordeaux') }

  before do
    assign(:procedure, procedure)
    assign(:groupe_instructeur, groupe_instructeur)
  end

  it 'renders the group header form' do
    render partial: 'administrateurs/groups_header'

    expect(rendered).to include('Groupe «')
    expect(rendered).to include(groupe_instructeur.label)
  end
end
