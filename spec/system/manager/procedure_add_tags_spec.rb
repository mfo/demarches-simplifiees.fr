# frozen_string_literal: true

describe 'Manager: ajout de tags sur une démarche', js: true do
  let(:super_admin) { create(:super_admin) }
  let(:procedure) { create(:procedure, :published) }

  before { login_as(super_admin, scope: :super_admin) }

  scenario 'un super admin ajoute un tag depuis la fiche démarche' do
    visit manager_procedure_path(procedure)

    find('.fr-ds-combobox__multiple input[role="combobox"]', wait: 10).fill_in(with: 'mon-tag')
    click_on 'Ajouter des tags'

    expect(page).to have_text('Le modèle est mis à jour')
    expect(procedure.reload.tags).to eq(['mon-tag'])
  end
end
