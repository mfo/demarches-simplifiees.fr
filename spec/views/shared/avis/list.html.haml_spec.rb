# frozen_string_literal: true

describe 'shared/avis/_list', type: :view do
  before do
    view.extend DossierHelper
    allow(view).to receive(:params).and_return({ statut: 'a-suivre' })
  end

  subject { render 'shared/avis/list', avis: avis_list, avis_seen_at: seen_at, expert_or_instructeur: instructeur }

  let(:instructeur) { instructeurs.default }
  let(:avis_list) { [avis.with_file] }
  let(:seen_at) { avis_list.first.created_at + 1.hour }

  it do
    is_expected.to have_text(avis_list.first.introduction)
    is_expected.not_to have_css(".highlighted")
  end

  context 'with a seen_at before avis created_at' do
    let(:seen_at) { avis_list.first.created_at - 1.hour }

    it do
      is_expected.to have_text("Fichier joint à la demande d’avis")
      is_expected.to have_css(".highlighted")
    end
  end

  context 'with an answer' do
    let(:avis_list) { [create(:avis, :with_answer, claimant: instructeur, experts_procedure: experts_procedures.default, dossier: dossiers.en_instruction)] }

    it 'renders the answer formatted with newlines' do
      expect(subject).to have_selector("p", text: avis_list.first.answer.split("\n").first)
      expect(subject).to have_selector("ul.list-style-type-none ul", count: 1) # avis.answer has two list item
      expect(subject).to have_selector("ul.list-style-type-none ul li", count: 2)
    end
  end

  context 'with another instructeur' do
    let(:instructeur) { create(:instructeur) }

    it 'shows the files attached to the avis request' do
      expect(subject).to have_text("Fichier joint à la demande d’avis")
    end
  end
end
