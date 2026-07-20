# frozen_string_literal: true

describe 'Breadcrumbs by role', js: false do
  describe 'as USAGER' do
    let(:user) { create(:user) }

    before { login_as user, scope: :user }

    scenario 'shows root "Accueil - Liste des dossiers" on /deleted_dossiers' do
      visit deleted_dossiers_path
      within('.fr-breadcrumb__list') do
        expect(page).to have_link('Accueil - Liste des dossiers', href: dossiers_path)
        expect(page).to have_text('Historique des dossiers supprimés')
      end
    end

    scenario 'shows root "Accueil - Liste des dossiers" on /profil and no Tableau de bord step' do
      visit profil_path
      within('.fr-breadcrumb__list') do
        expect(page).to have_link('Accueil - Liste des dossiers', href: dossiers_path)
        expect(page).not_to have_text('Tableau de bord')
        expect(page).to have_text('Profil')
      end
    end
  end

  describe 'as ADMINISTRATEUR' do
    let(:administrateur) { create(:administrateur) }

    before { login_as administrateur.user, scope: :user }

    scenario 'shows root "Accueil - Liste des démarches" on /profil' do
      visit profil_path
      within('.fr-breadcrumb__list') do
        expect(page).to have_link('Accueil - Liste des démarches', href: admin_procedures_path)
      end
    end

    scenario 'shows "Démarches publiées" tab label for a published procedure' do
      procedure = create(:procedure, :published, administrateur: administrateur)
      visit champs_admin_procedure_path(procedure)
      within('.fr-breadcrumb__list') do
        expect(page).to have_link('Démarches publiées', href: admin_procedures_path(statut: 'publiees'))
      end
    end

    scenario 'shows "Démarches en test" tab label for a draft procedure' do
      procedure = create(:procedure, administrateur: administrateur)
      visit champs_admin_procedure_path(procedure)
      within('.fr-breadcrumb__list') do
        expect(page).to have_link('Démarches en test', href: admin_procedures_path(statut: 'brouillons'))
      end
    end

    scenario 'shows "Démarches terminées" tab label for a closed procedure' do
      procedure = create(:procedure, :closed, administrateur: administrateur)
      visit champs_admin_procedure_path(procedure)
      within('.fr-breadcrumb__list') do
        expect(page).to have_link('Démarches terminées', href: admin_procedures_path(statut: 'archivees'))
      end
    end
  end

  describe 'as EXPERT' do
    let(:pending_avis) { avis.pending }

    before { login_as users.expert, scope: :user }

    scenario 'shows root "Accueil - Avis" on the dossier review page' do
      visit expert_avis_path(pending_avis.procedure, pending_avis)
      within('.fr-breadcrumb__list') do
        expect(page).to have_link('Accueil - Avis', href: expert_all_avis_path)
      end
    end
  end

  describe 'as GESTIONNAIRE' do
    let(:gestionnaire) { create(:gestionnaire) }

    before { login_as gestionnaire.user, scope: :user }

    scenario 'shows root "Accueil - Liste des groupes" on the gestionnaire dashboard' do
      visit gestionnaire_groupe_gestionnaires_path
      within('.fr-breadcrumb__list') do
        expect(page).to have_link('Accueil - Liste des groupes', href: gestionnaire_groupe_gestionnaires_path)
      end
    end
  end

  describe 'with explicit ?context= override' do
    let(:user) { create(:administrateur).user }

    before { login_as user, scope: :user }

    scenario 'forces administrateur root on /profil?context=administrateur' do
      visit profil_path(context: 'administrateur')
      within('.fr-breadcrumb__list') do
        expect(page).to have_link('Accueil - Liste des démarches', href: admin_procedures_path)
      end
    end

    scenario 'falls back to user role when ?context=invalid' do
      visit profil_path(context: 'pirate')
      within('.fr-breadcrumb__list') do
        expect(page).to have_link('Accueil - Liste des démarches', href: admin_procedures_path)
      end
    end
  end
end
