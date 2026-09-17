# frozen_string_literal: true

RSpec.describe GroupeGestionnaire::MessageComponent, type: :component do
  let(:component) do
    described_class.new(
      commentaire: commentaire,
      connected_user: connected_user,
      groupe_gestionnaire: groupe_gestionnaire,
      messagerie_seen_at: seen_at
    )
  end

  before do
    allow(component).to receive(:params).and_return({ statut: 'a-suivre' })
  end

  let(:seen_at) { commentaire.created_at + 1.hour }
  let(:commentaire) { create(:commentaire_groupe_gestionnaire, sender: administrateurs.default) }
  let(:groupe_gestionnaire) { commentaire.groupe_gestionnaire }
  let(:connected_user) { commentaire.sender }

  subject { render_inline(component).to_html }

  context 'escape <img> tag' do
    before { commentaire.update(body: '<img src="demarche.numerique.gouv.fr" />Hello') }

    it { is_expected.not_to have_selector('img[src="demarche.numerique.gouv.fr"]') }
  end

  context 'with a seen_at after commentaire created_at' do
    it { is_expected.not_to have_css(".highlighted") }
  end

  context 'with a gestionnaire message' do
    let(:gestionnaire) { create(:gestionnaire) }
    let(:commentaire) { create(:commentaire_groupe_gestionnaire, sender: administrateurs.default, gestionnaire: gestionnaire, body: 'Second message') }

    it 'displays the gestionnaire’s email' do
      is_expected.to have_text(gestionnaire.email)
    end

    describe 'delete message button for gestionnaire' do
      let(:connected_user) { gestionnaire }
      let(:form_url) { component.helpers.gestionnaire_groupe_gestionnaire_commentaire_path(groupe_gestionnaire, commentaire, statut: 'a-suivre') }

      context 'when commentaire had been written by connected gestionnaire' do
        it { is_expected.to have_selector("form[action=\"#{form_url}\"]") }
      end

      context 'when commentaire had been written by connected gestionnaire and discarded' do
        let(:commentaire) { create(:commentaire_groupe_gestionnaire, sender: administrateurs.default, gestionnaire: gestionnaire, body: 'Second message', discarded_at: 2.days.ago) }

        it do
          is_expected.not_to have_selector("form[action=\"#{form_url}\"]")
          is_expected.to have_selector(".rich-text", text: component.t('.deleted_body'))
        end
      end

      context 'when commentaire had been written by another gestionnaire' do
        let(:commentaire) { create(:commentaire_groupe_gestionnaire, sender: administrateurs.default, gestionnaire: create(:gestionnaire), body: 'Second message') }

        it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
      end
    end
  end

  describe '#commentaire_date' do
    let(:present_date) { Time.zone.local(2018, 9, 2, 10, 5, 0) }
    let(:creation_date) { present_date }
    let(:commentaire) do
      travel_to(creation_date) { create(:commentaire_groupe_gestionnaire, sender: administrateurs.default) }
    end

    subject do
      travel_to(present_date) { component.send(:commentaire_date) }
    end

    it 'formats as numeric date with year' do
      expect(subject).to eq 'Le 02/09/2018 10:05'
    end

    context 'when displaying a commentaire created on a previous year' do
      let(:creation_date) { present_date.prev_year }

      it 'formats as numeric date with previous year' do
        expect(subject).to eq 'Le 02/09/2017 10:05'
      end
    end

    context 'when formatting the first day of the month' do
      let(:present_date) { Time.zone.local(2018, 9, 1, 10, 5, 0) }

      it 'formats as numeric date for first day of month' do
        expect(subject).to eq 'Le 01/09/2018 10:05'
      end
    end
  end
end
