# frozen_string_literal: true

describe 'users/dossiers/expiration_banner', type: :view do
  include DossierHelper
  let(:duree_conservation_dossiers_dans_ds) { 3 }
  let(:dossier) do
    create(:dossier, state, attributes.merge(
                              state: state,
                              conservation_extension: 1,
                              procedure: create(:procedure, duree_conservation_dossiers_dans_ds: duree_conservation_dossiers_dans_ds)
                            ))
  end
  let(:i18n_key_state) { state }
  subject do
    dossier.update_expired_at unless dossier.en_instruction?
    render('users/dossiers/expiration_banner',
           dossier: dossier,
           current_user: build(:user))
  end

  context 'with dossier.brouillon?' do
    let(:attributes) { { created_at: 6.months.ago } }
    let(:state) { :brouillon }

    it 'render estimated expiration date' do
      expect(subject).to have_selector('.expires_at',
                                       text: I18n.t("shared.dossiers.header.expires_at.#{i18n_key_state}",
                                                    date: safe_expiration_date(dossier),
                                                    duree_conservation_totale: duree_conservation_dossiers_dans_ds))
    end
  end

  context 'with dossier.en_construction?' do
    let(:attributes) { { en_construction_at: 6.months.ago } }
    let(:state) { :en_construction }

    it 'does not render any expiration message (#13178)' do
      expect(subject).not_to have_selector('.expires_at')
      expect(subject).not_to have_selector('p.expires_at_en_instruction')
    end
  end

  context 'with dossier.en_processed_at?' do
    let(:state) { :accepte }
    let(:attributes) { {} }

    it 'render estimated expiration date' do
      allow(dossier).to receive(:processed_at).and_return(6.months.ago)
      expect(subject).to have_selector('.expires_at',
                                       text: I18n.t("shared.dossiers.header.expires_at.#{i18n_key_state}",
                                                    date: safe_expiration_date(dossier),
                                                    duree_conservation_totale: duree_conservation_dossiers_dans_ds))
    end
  end

  context 'when close to expiration' do
    let(:expiration_enabled) { true }

    before { allow(dossier).to receive(:close_to_expiration?).and_return(true) }

    context 'with a brouillon' do
      let(:attributes) { { created_at: 6.months.ago } }
      let(:state) { :brouillon }

      it 'renders the orange callout with the postpone button' do
        expect(subject).to have_selector('.fr-callout.fr-callout--orange-terre-battue')
        expect(subject).to have_selector('#test-user-repousser-expiration')
      end
    end

    context 'with a termine dossier' do
      let(:attributes) { { processed_at: 6.months.ago } }
      let(:state) { :accepte }

      it 'renders the orange callout without any action button (download is handled by the header)' do
        expect(subject).to have_selector('.fr-callout.fr-callout--orange-terre-battue')
        expect(subject).not_to have_selector('#test-user-repousser-expiration')
        expect(subject).not_to have_selector('.fr-callout a')
        expect(subject).not_to have_selector('.fr-callout button')
      end
    end
  end
end
