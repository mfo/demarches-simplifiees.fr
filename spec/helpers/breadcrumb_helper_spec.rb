# frozen_string_literal: true

describe BreadcrumbHelper do
  describe '#breadcrumb_root_for' do
    subject { helper.breadcrumb_root_for(profile) }

    context 'when profile is :user' do
      let(:profile) { :user }
      it { is_expected.to eq(['Accueil - Liste des dossiers', helper.dossiers_path]) }
    end

    context 'when profile is :instructeur' do
      let(:profile) { :instructeur }
      it { is_expected.to eq(['Accueil - Liste des démarches', helper.instructeur_procedures_path]) }
    end

    context 'when profile is :administrateur' do
      let(:profile) { :administrateur }
      it { is_expected.to eq(['Accueil - Liste des démarches', helper.admin_procedures_path]) }
    end

    context 'when profile is :expert' do
      let(:profile) { :expert }
      it { is_expected.to eq(['Accueil - Avis', helper.expert_all_avis_path]) }
    end

    context 'when profile is :gestionnaire' do
      let(:profile) { :gestionnaire }
      it { is_expected.to eq(['Accueil - Liste des groupes', helper.gestionnaire_groupe_gestionnaires_path]) }
    end

    context 'when profile is unknown' do
      let(:profile) { :guest }
      it { is_expected.to eq(['Accueil - Liste des démarches', helper.root_path]) }
    end

    context 'when profile is nil' do
      let(:profile) { nil }
      it { is_expected.to eq(['Accueil - Liste des démarches', helper.root_path]) }
    end
  end
end
