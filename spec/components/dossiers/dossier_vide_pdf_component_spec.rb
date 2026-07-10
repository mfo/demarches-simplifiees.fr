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

  describe 'mailing instruction' do
    context 'with a service' do
      let(:service) { create(:service, nom: 'DDT du Rhône', adresse: "12 rue de la Paix\n69000 Lyon") }
      let(:procedure) { create(:procedure, :published, service:) }

      it 'tells where to send the form on a single line' do
        expect(subject).to have_selector('.mailing', text: 'À envoyer à DDT du Rhône - 12 rue de la Paix 69000 Lyon')
      end
    end

    context 'without a service' do
      let(:procedure) { create(:procedure, :published, service: nil) }

      it { is_expected.not_to have_selector('.mailing') }
    end
  end

  describe 'dispatch per champ type' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public:) }

    context 'header_section' do
      let(:types_de_champ_public) do
        [
          { type: :header_section, libelle: 'Niveau 1', level: 1 },
          { type: :header_section, libelle: 'Niveau 2', level: 2 },
          { type: :header_section, libelle: 'Niveau 3', level: 3 },
        ]
      end

      it 'maps each section level to a heading below the h2 form title' do
        expect(subject).to have_selector('h3', text: 'Niveau 1')
        expect(subject).to have_selector('h4', text: 'Niveau 2')
        expect(subject).to have_selector('h5', text: 'Niveau 3')
      end
    end

    context 'yes_no' do
      let(:types_de_champ_public) { [{ type: :yes_no, libelle: 'D’accord ?' }] }

      it 'renders two Oui/Non checkboxes with real labels' do
        expect(subject).to have_content('D’accord ?')
        expect(subject).to have_content('Oui')
        expect(subject).to have_content('Non')
        expect(subject).to have_selector('.checkbox[aria-hidden="true"]', count: 2)
      end

      it 'explains the applicable option must be checked' do
        expect(subject).to have_content('Cochez la mention applicable')
      end
    end

    context 'civilite' do
      let(:types_de_champ_public) { [{ type: :civilite, libelle: 'Civilité' }] }

      it { is_expected.to have_selector('.checkbox', count: 2) }
    end

    context 'simple drop_down_list' do
      let(:types_de_champ_public) do
        [{ type: :drop_down_list, libelle: 'Choix', options: ['A', 'B', 'C'] }]
      end

      it 'renders an options list without <p> inside <li>' do
        expect(subject).to have_selector('ul li', count: 3)
        expect(subject).not_to have_selector('li p')
      end

      it 'explains a single value can be selected' do
        expect(subject).to have_content('Cochez la mention applicable, une seule valeur possible')
      end
    end

    context 'simple drop_down_list with too many options' do
      let(:options) { (1..Champs::DropDownListChamp::THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE).map { |i| "Option #{i}" } }
      let(:types_de_champ_public) do
        [{ type: :drop_down_list, libelle: 'Choix', options: }]
      end

      it 'falls back to a fillable box in the form, without listing options inline' do
        expect(subject).to have_content('Choix')
        expect(subject).to have_selector('.champ .box')
        expect(subject).not_to have_selector('.champ ul.options li')
      end

      it 'references the annex from the form field with the single-value instruction' do
        expect(subject).to have_selector('.champ', text: 'La liste complète des options figure en Annexe 1. Renseignez la mention applicable, une seule valeur possible')
      end

      it 'lists every option as a plain list without checkboxes in an Annexes page' do
        expect(subject).to have_selector('section.annexes h2', text: 'Annexes')
        expect(subject).to have_selector('.annexes h3', text: 'Annexe 1 : Choix')
        expect(subject).to have_selector('.annexes ul li', count: options.size)
        expect(subject).not_to have_selector('.annexes .checkbox')
      end
    end

    context 'multiple_drop_down_list' do
      let(:types_de_champ_public) do
        [{ type: :multiple_drop_down_list, libelle: 'Choix', options: ['A', 'B'] }]
      end

      it { is_expected.to have_selector('ul li', count: 2) }

      it 'explains several values can be selected' do
        expect(subject).to have_content('Cochez la mention applicable, plusieurs valeurs possibles')
      end
    end

    context 'multiple_drop_down_list with too many options' do
      let(:options) { (1..Champs::DropDownListChamp::THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE).map { |i| "Option #{i}" } }
      let(:types_de_champ_public) do
        [{ type: :multiple_drop_down_list, libelle: 'Choix', options: }]
      end

      it 'falls back to a fillable box in the form, without listing options inline' do
        expect(subject).to have_content('Choix')
        expect(subject).to have_selector('.champ .box')
        expect(subject).not_to have_selector('.champ ul.options li')
      end

      it 'references the annex from the form field with the multiple-values instruction' do
        expect(subject).to have_selector('.champ', text: 'La liste complète des options figure en Annexe 1. Renseignez les mentions applicables, plusieurs valeurs possibles')
      end

      it 'lists every option as a plain list without checkboxes' do
        expect(subject).to have_selector('.annexes h3', text: 'Annexe 1 : Choix')
        expect(subject).to have_selector('.annexes ul li', count: options.size)
        expect(subject).not_to have_selector('.annexes .checkbox')
      end
    end

    context 'several champs with too many options' do
      let(:options) { (1..Champs::DropDownListChamp::THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE).map { |i| "Option #{i}" } }
      let(:types_de_champ_public) do
        [
          { type: :drop_down_list, libelle: 'Premier', options: },
          { type: :multiple_drop_down_list, libelle: 'Second', options: },
        ]
      end

      it 'numbers the annexes in document order' do
        expect(subject).to have_selector('.annexes h3', text: 'Annexe 1 : Premier')
        expect(subject).to have_selector('.annexes h3', text: 'Annexe 2 : Second')
      end
    end

    context 'no champ needs an annex' do
      let(:types_de_champ_public) { [{ type: :text, libelle: 'Votre nom' }] }

      it 'does not render an Annexes section' do
        expect(subject).not_to have_selector('section.annexes')
      end
    end

    context 'piece_justificative' do
      let(:types_de_champ_public) { [{ type: :piece_justificative, libelle: 'RIB' }] }

      it { is_expected.to have_content('RIB') }
    end

    context 'repetition' do
      let(:types_de_champ_public) do
        [{ type: :repetition, libelle: 'Personnes', children: [{ type: :text, libelle: 'Nom' }] }]
      end

      it 'renders 3 occurrences of the child champ' do
        expect(subject).to have_content('Nom', count: 3)
      end
    end

    context 'default text champ' do
      let(:types_de_champ_public) { [{ type: :text, libelle: 'Votre nom' }] }

      it 'renders a label and a fillable box' do
        expect(subject).to have_content('Votre nom')
        expect(subject).to have_selector('.box')
      end
    end
  end
end
