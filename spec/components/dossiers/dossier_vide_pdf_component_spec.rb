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

  describe 'conditional champ' do
    let(:public_type_de_champs) do
      [
        { type: :drop_down_list, libelle: 'Choix simple', options: ['Fromage', 'Dessert'] },
        { type: :text, libelle: 'Précisez' },
      ]
    end
    let(:procedure) { create(:procedure, :published, public_type_de_champs:) }
    let(:source) { procedure.active_revision.type_de_champs.find { it.libelle == 'Choix simple' } }
    let(:target) { procedure.active_revision.type_de_champs.find { it.libelle == 'Précisez' } }

    def set_condition(condition) = target.update!(condition:)

    context 'with an equality condition' do
      before { set_condition(Logic::Eq.new(Logic::ChampValue.new(source.stable_id), Logic::Constant.new('Dessert'))) }

      it 'renders a humanized instruction inside the conditional block' do
        expect(subject).to have_selector('.champ--conditional .condition', text: 'À remplir si « Choix simple » égal à « Dessert »')
      end

      it 'marks only the conditional champ' do
        expect(subject).to have_selector('.champ', count: 2)
        expect(subject).to have_selector('.champ--conditional', count: 1)
      end
    end

    context 'with a negated condition' do
      before { set_condition(Logic::NotEq.new(Logic::ChampValue.new(source.stable_id), Logic::Constant.new('Fromage'))) }

      it { is_expected.to have_selector('.condition', text: 'À remplir si « Choix simple » n’est pas « Fromage »') }
    end

    context 'with a composed OR condition' do
      before do
        set_condition(Logic::Or.new([
          Logic::Eq.new(Logic::ChampValue.new(source.stable_id), Logic::Constant.new('Dessert')),
          Logic::Eq.new(Logic::ChampValue.new(source.stable_id), Logic::Constant.new('Fromage')),
        ]))
      end

      it { is_expected.to have_selector('.condition', text: 'À remplir si « Choix simple » égal à « Dessert » ou « Choix simple » égal à « Fromage »') }
    end

    context 'without a condition' do
      it 'renders no condition instruction and no conditional block' do
        expect(subject).not_to have_selector('.condition')
        expect(subject).not_to have_selector('.champ--conditional')
      end
    end

    context 'with an unfinished condition (empty operator)' do
      before { set_condition(Logic::EmptyOperator.new(Logic::Empty.new, Logic::Empty.new)) }

      it 'ignores it entirely (no translation-missing instruction, no shading)' do
        expect(subject).not_to have_selector('.condition')
        expect(subject).not_to have_selector('.champ--conditional')
        expect(subject).not_to have_text('translation missing', normalize_ws: true)
      end
    end
  end

  describe 'admin rich text (parity with the web SimpleFormat rendering)' do
    subject { render_inline(described_class.new(revision: procedure.active_revision)) }

    let(:procedure) { create(:procedure, :published, description: 'Présentation en <b>valorisée</b>', public_type_de_champs:) }

    context 'formatting tags' do
      let(:public_type_de_champs) do
        [
          { type: :text, libelle: 'Nom', description: 'Consigne en <b>appuyée</b>' },
          { type: :explication, libelle: 'Infos', description: 'Détail en <b>souligné</b>' },
        ]
      end

      it 'renders the procedure presentation tags instead of escaping them' do
        expect(subject).to have_selector('.presentation b', text: 'valorisée')
      end

      it 'renders a champ description tags instead of stripping them' do
        expect(subject).to have_selector('.champ .description b', text: 'appuyée')
      end

      it 'renders an explication body tags' do
        expect(subject).to have_selector('.explication b', text: 'souligné')
      end
    end

    context 'authored line breaks' do
      let(:public_type_de_champs) do
        [{ type: :text, libelle: 'Nom', description: "Ligne 1\nLigne 2" }]
      end

      it 'keeps them as separate paragraphs, like the web' do
        expect(subject).to have_selector('.champ .description p', count: 2)
      end
    end
  end

  describe 'dispatch per champ type' do
    let(:procedure) { create(:procedure, :published, public_type_de_champs:) }

    context 'header_section' do
      let(:public_type_de_champs) do
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
      let(:public_type_de_champs) { [{ type: :yes_no, libelle: 'D’accord ?' }] }

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
      let(:public_type_de_champs) { [{ type: :civilite, libelle: 'Civilité' }] }

      it { is_expected.to have_selector('.checkbox', count: 2) }
    end

    context 'simple drop_down_list' do
      let(:public_type_de_champs) do
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
      let(:public_type_de_champs) do
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
        expect(subject).to have_selector('.annexes ul.annex-options li', count: options.size)
        expect(subject).not_to have_selector('.annexes .checkbox')
      end
    end

    context 'multiple_drop_down_list' do
      let(:public_type_de_champs) do
        [{ type: :multiple_drop_down_list, libelle: 'Choix', options: ['A', 'B'] }]
      end

      it { is_expected.to have_selector('ul li', count: 2) }

      it 'explains several values can be selected' do
        expect(subject).to have_content('Cochez la mention applicable, plusieurs valeurs possibles')
      end
    end

    context 'multiple_drop_down_list with too many options' do
      let(:options) { (1..Champs::DropDownListChamp::THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE).map { |i| "Option #{i}" } }
      let(:public_type_de_champs) do
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
        expect(subject).to have_selector('.annexes ul.annex-options li', count: options.size)
        expect(subject).not_to have_selector('.annexes .checkbox')
      end
    end

    context 'list too large to print' do
      let(:online_url) { Rails.application.routes.url_helpers.commencer_url(procedure.path) }

      before { stub_const("#{described_class}::MAX_PRINTABLE_OPTIONS", 3) }

      context 'drop_down_list' do
        let(:public_type_de_champs) do
          [{ type: :drop_down_list, libelle: 'Commune', options: ['Lyon', 'Paris', 'Rennes', 'Toulouse'] }]
        end

        it 'refers to the online form instead of printing the list' do
          expect(subject).to have_selector('.champ .box')
          expect(subject).to have_content('4 valeurs')
          expect(subject).to have_selector("a[href='#{online_url}']", text: online_url)
        end

        it 'does not render an annex' do
          expect(subject).not_to have_selector('section.annexes')
          expect(subject).not_to have_content('Lyon')
        end
      end

      context 'linked_drop_down_list' do
        let(:public_type_de_champs) do
          [{ type: :linked_drop_down_list, libelle: 'Lieu', options: ['--Rhône--', 'Lyon', 'Villeurbanne', '--Ille-et-Vilaine--', 'Rennes'] }]
        end

        it 'prints neither the primary nor the secondary options' do
          expect(subject).to have_selector('.champ .box')
          expect(subject).to have_content(online_url)
          expect(subject).not_to have_content('Rhône')
          expect(subject).not_to have_content('Lyon')
        end
      end
    end

    context 'linked_drop_down_list small enough to print' do
      let(:public_type_de_champs) do
        [{ type: :linked_drop_down_list, libelle: 'Lieu', options: ['--Rhône--', 'Lyon', 'Villeurbanne'] }]
      end

      it 'lists every level inline, as today' do
        expect(subject).to have_content('Rhône')
        expect(subject).to have_content('Lyon')
        expect(subject).to have_selector('li.secondary', count: 2)
      end
    end

    context 'several champs with too many options' do
      let(:options) { (1..Champs::DropDownListChamp::THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE).map { |i| "Option #{i}" } }
      let(:public_type_de_champs) do
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
      let(:public_type_de_champs) { [{ type: :text, libelle: 'Votre nom' }] }

      it 'does not render an Annexes section' do
        expect(subject).not_to have_selector('section.annexes')
      end
    end

    context 'piece_justificative' do
      let(:public_type_de_champs) { [{ type: :piece_justificative, libelle: 'RIB' }] }

      it { is_expected.to have_content('RIB') }
    end

    context 'repetition' do
      let(:public_type_de_champs) do
        [{ type: :repetition, libelle: 'Personnes', children: [{ type: :text, libelle: 'Nom' }] }]
      end

      it 'renders 3 occurrences of the child champ' do
        expect(subject).to have_content('Nom', count: 3)
      end
    end

    context 'default text champ' do
      let(:public_type_de_champs) { [{ type: :text, libelle: 'Votre nom' }] }

      it 'renders a label and a fillable box' do
        expect(subject).to have_content('Votre nom')
        expect(subject).to have_selector('.box')
      end
    end
  end
end
