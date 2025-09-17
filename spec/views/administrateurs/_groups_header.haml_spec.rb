# frozen_string_literal: true

describe 'administrateurs/_groups_header.haml', type: :view do
  let(:groupe_instructeur) { create(:groupe_instructeur, label: 'Groupe Test') }
  let(:procedure) { groupe_instructeur.procedure }
  let(:update_path) { '/admin/procedures/groups/1' }

  before do
    assign(:groupe_instructeur, groupe_instructeur)
    assign(:procedure, procedure)

    allow(view).to receive(:admin_procedure_groupe_instructeur_path).with(procedure, groupe_instructeur).and_return(update_path)

    render partial: 'administrateurs/groups_header'
  end

  it 'renders the group form' do
    expect(rendered).to include('Groupe « Groupe Test »')
    expect(rendered).to have_selector("form[action='#{update_path}']")
  end
end
