# frozen_string_literal: true

RSpec.describe 'shared/archives/_notice', type: :view do
  subject { render 'shared/archives/notice', with_bills: with_bills }

  # with_bills mirrors PiecesJustificativesService#liste_documents_allows?(:with_bills):
  # true for an Administrateur, false for an Instructeur.
  context 'when the archive carries the bills (administrateur)' do
    let(:with_bills) { true }

    it 'announces the horodatage directories' do
      expect(subject).to have_text('horodatage/')
      expect(subject).to have_text('bills/')
    end
  end

  context 'when the archive does not carry the bills (instructeur)' do
    let(:with_bills) { false }

    it 'does not announce directories the instructeur will never receive' do
      expect(subject).not_to have_text('horodatage/')
      expect(subject).not_to have_text('bills/')
    end

    it 'still announces the directories every profile receives' do
      expect(subject).to have_text('pieces_justificatives/')
      expect(subject).to have_text('messagerie/')
      expect(subject).to have_text('avis/')
      expect(subject).to have_text('-LISTE-DES-FICHIERS-EN-ERREURS.txt')
    end
  end
end
