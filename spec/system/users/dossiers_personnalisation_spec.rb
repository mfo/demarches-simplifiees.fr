# frozen_string_literal: true

describe 'Usager personnalise la liste des dossiers', js: true do
  let(:user) { create(:user) }
  let(:procedure) do
    create(:procedure, :published, types_de_champ_public: [
      { type: :header_section, libelle: 'Identité' },
      { type: :text, libelle: 'Nom du titre', mandatory: true },
      { type: :text, libelle: 'Numéro CPPAP' },
    ])
  end

  before do
    Flipper.enable(:dossiers_list_personnalisation, user)
    create_list(:dossier, 6, :en_construction, user:, procedure:)
    login_as user, scope: :user
  end

  it 'lets the user pick fields and persists the personnalisation' do
    visit dossiers_path

    expect(page).to have_css('.mes-dossiers-header__personnalisation')
    find('.mes-dossiers-header__personnalisation').click

    expect(page).to have_content('Personnaliser la liste des dossiers')
    expect(page).to have_content(procedure.libelle)
    find('.dom-ready')

    find('button.fr-select', match: :first).click

    expect(page).to have_css('.dropdown-section-header', text: 'Identité')
    expect(page).to have_css('[role="option"]', text: 'Nom du titre *')

    find('[role="option"]', text: 'Nom du titre').click
    find('[role="option"]', text: 'Numéro CPPAP').click
    send_keys(:escape)

    click_button('Enregistrer')

    expect(page).to have_content('La liste des dossiers a bien été personnalisée.')

    perso = DossiersListPersonnalisation.find_by(user:, procedure:)
    expect(perso.displayed_columns.size).to eq(2)
  end
end
