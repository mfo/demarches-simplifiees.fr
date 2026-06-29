# frozen_string_literal: true

RSpec.describe Dossiers::DossierVidePdfComponent, type: :component do
  subject { render_inline(described_class.new(revision: procedure.active_revision)) }

  describe 'header and identity' do
    context 'procedure for a legal entity' do
      let(:procedure) do
        create(:procedure, :published, libelle: 'Ma démarche', for_individual: false)
      end

      it 'renders the title, header and establishment identity' do
        expect(subject).to have_selector('h1', text: 'Ma démarche')
        expect(subject).to have_selector('h2', text: 'Identité du demandeur')
        expect(subject).to have_selector('h2', text: 'Formulaire')
        expect(subject).to have_content('SIRET')
        expect(subject).to have_selector('img[alt]')
        # non-empty alt (PDF/UA safeguard)
        expect(subject.at_css('img')['alt']).to be_present
      end
    end

    context 'procedure for an individual' do
      let(:procedure) do
        create(:procedure, :published, for_individual: true)
      end

      it 'renders the individual identity' do
        expect(subject).to have_content('Nom')
        expect(subject).to have_content('Prénom')
        expect(subject).not_to have_content('SIRET')
      end
    end
  end
end
