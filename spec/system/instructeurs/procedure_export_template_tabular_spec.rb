# frozen_string_literal: true

describe "procedure exports" do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public:, instructeurs: [instructeur]) }
  let(:types_de_champ_public) { [{ type: :text }] }

  before do
    login_as(instructeur.user, scope: :user)

    unless InstructeursProcedure.exists?(instructeur: instructeur, procedure: procedure)
      create(:instructeurs_procedure, instructeur: instructeur, procedure: procedure)
    end
  end

  scenario "create an export_template tabular", js: true do
    Flipper.enable(:export_template, procedure)
    visit instructeur_procedure_path(procedure)

    find("button", text: "Téléchargements").click

    click_on "Modèles d'export"

    click_on "Créer un modèle d'export tabulaire"

    fill_in "Nom du modèle", with: "Mon modèle"

    find("#informations-usager-fieldset label", text: "Tout sélectionner").click

    within '#informations-usager-fieldset' do
      expect(all('input[type=checkbox]').all?(&:checked?)).to be_truthy
    end

    find("#informations-dossier-fieldset label", text: "Tout sélectionner").click

    within '#informations-dossier-fieldset' do
      expect(all('input[type=checkbox]').all?(&:checked?)).to be_truthy
    end

    click_on "Enregistrer"

    expect(page).to have_content('Mon modèle')

    # check if all usager colonnes are selected
    #
    click_on 'Mon modèle'

    within '#informations-usager-fieldset' do
      expect(all('input[type=checkbox]').all?(&:checked?)).to be_truthy
    end

    within '#informations-dossier-fieldset' do
      expect(all('input[type=checkbox]').all?(&:checked?)).to be_truthy
    end

    # uncheck checkboxes
    find("#informations-dossier-fieldset label", text: "Tout sélectionner").click
    within '#informations-dossier-fieldset' do
      expect(all('input[type=checkbox]').none?(&:checked?)).to be_truthy
    end
  end
end
