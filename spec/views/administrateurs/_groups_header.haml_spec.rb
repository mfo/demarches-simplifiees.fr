# frozen_string_literal: true

describe 'administrateurs/_groups_header', type: :view do
  let(:procedure) { build(:procedure, id: 42) }
  let(:groupe_instructeur) { build(:groupe_instructeur, procedure: procedure, id: 7, closed: false) }
  let(:update_path) { '/admin/procedures/42/groupes/7' }

  before do
    assign(:procedure, procedure)
    assign(:groupe_instructeur, groupe_instructeur)
    allow(view).to receive(:admin_procedure_groupe_instructeur_path).with(procedure, groupe_instructeur).and_return(update_path)
  end

  it 'renders the group header form' do
    render

    expect(rendered).to include("Groupe « #{groupe_instructeur.label} »")
    expect(rendered).to include(update_path)
    expect(rendered).to include('Modifier le groupe')
  end
end
