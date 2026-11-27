# frozen_string_literal: true

describe RevisionDraftEditingConcern do
  let(:procedure) do
    create(:procedure, public_type_de_champs: [
      { type: :integer_number, libelle: 'age' },
      { type: :repetition, libelle: 'enfants', children: [{ libelle: 'prénom' }] },
      { type: :yes_no, libelle: 'boursier' },
    ])
  end
  let(:draft) { procedure.draft_revision }

  def stable_id(libelle) = draft.reload.type_de_champs.find { it.libelle == libelle }.stable_id
  def libelles = draft.reload.public_root_type_de_champs.map(&:libelle)

  def child(libelle) = draft.reload.type_de_champs.find { it.libelle == libelle }
  def equals(stable_id) = Logic::Eq.new(Logic::ChampValue.new(stable_id), Logic::Constant.new(18))

  shared_examples 'a refusal naming' do |target_libelle, dependent_libelle|
    it 'is refused and the champ stays in the draft' do
      expect(subject).not_to be_success
      expect(subject.errors.first).to include(target_libelle, dependent_libelle)
      expect(draft.reload.type_de_champs.map(&:libelle)).to include(target_libelle)
    end
  end

  describe '#remove_type_de_champ_checked' do
    subject { draft.remove_type_de_champ_checked(target) }

    let(:target) { stable_id('boursier') }

    it 'removes the type de champ' do
      expect(subject).to be_success
      expect(subject.stable_id).to eq(target.to_s)
      expect(libelles).to eq(['age', 'enfants'])
    end

    context 'with a repetition' do
      let(:target) { stable_id('enfants') }

      it 'removes it with its children' do
        expect(subject).to be_success
        expect(libelles).to eq(['age', 'boursier'])
      end
    end

    context 'with a stable id given as a string' do
      let(:target) { stable_id('boursier').to_s }

      it { expect(subject).to be_success }
    end

    ['abc', '12abc', '', nil, 'Champ-1', '0x1F', '0b1'].each do |invalid|
      context "with #{invalid.inspect}" do
        let(:target) { invalid }

        it 'is not found' do
          expect(subject).not_to be_success
          expect(subject.errors).to eq(["Le champ « #{invalid} » n’existe pas dans le brouillon de cette démarche."])
        end
      end
    end

    context 'with a decimal stable id padded with zeros' do
      let!(:real_stable_id) { stable_id('boursier').to_s }
      let(:target) { "0#{real_stable_id}" }

      it 'resolves to the champ and reports its real stable id' do
        expect(subject).to be_success
        expect(subject.stable_id).to eq(real_stable_id)
      end
    end

    context 'with a stable id of nowhere' do
      let(:target) { 0 }

      it { expect(subject.errors.first).to include('n’existe pas dans le brouillon') }
    end

    context 'when a condition reads the type de champ' do
      before do
        age = Logic::ChampValue.new(stable_id('age'))
        draft.type_de_champs.find { it.libelle == 'boursier' }.update!(condition: Logic::Eq.new(age, Logic::Constant.new(18)))
      end

      let(:target) { stable_id('age') }

      it 'is refused and names the dependent' do
        expect(subject).not_to be_success
        expect(subject.errors.first).to include('« age »', '« boursier »')
        expect(libelles).to include('age')
      end

      it 'carries no French guillemets in English' do
        I18n.with_locale(:en) { expect(subject.errors.first).not_to include('«', '»') }
      end
    end

    context 'when a repetition child reads the type de champ' do
      before { child('prénom').update!(condition: equals(stable_id('age'))) }

      let(:target) { stable_id('age') }

      it_behaves_like 'a refusal naming', 'age', 'prénom'
    end

    context 'when a repetition child is read by a sibling child' do
      before do
        draft.type_de_champs.find { it.libelle == 'enfants' }.tap do |repetition|
          sibling = draft.add_type_de_champ({ type_champ: 'integer_number', libelle: 'rang', parent_stable_id: repetition.stable_id })
          child('prénom').update!(condition: equals(sibling.stable_id))
        end
      end

      let(:target) { stable_id('rang') }

      it_behaves_like 'a refusal naming', 'rang', 'prénom'
    end

    context 'when a private annotation is read by a public champ' do
      before do
        note = draft.add_type_de_champ({ type_champ: 'integer_number', libelle: 'note', private: true })
        draft.type_de_champs.find { it.libelle == 'boursier' }.update!(condition: equals(note.stable_id))
      end

      let(:target) { stable_id('note') }

      it_behaves_like 'a refusal naming', 'note', 'boursier'
    end

    context 'when a repetition is removed with a child conditioned on a sibling' do
      before do
        repetition = draft.type_de_champs.find { it.libelle == 'enfants' }
        sibling = draft.add_type_de_champ({ type_champ: 'integer_number', libelle: 'rang', parent_stable_id: repetition.stable_id })
        child('prénom').update!(condition: equals(sibling.stable_id))
      end

      let(:target) { stable_id('enfants') }

      it { expect(subject).to be_success }
    end

    context 'when the type de champ is locked' do
      before do
        draft.update!(ineligibilite_enabled: true, ineligibilite_message: 'Inéligible', ineligibilite_rules: equals(stable_id('boursier')))
      end

      it 'is refused with the reason of the editor' do
        expect(subject.errors).to eq([I18n.t('activerecord.errors.type_de_champ.locked.destroy.used_by_ineligibilite_rules', type_de_champ: 'boursier')])
        expect(libelles).to include('boursier')
      end
    end

    context 'when the procedure is published meanwhile' do
      before { draft.update_columns(published_at: Time.zone.now) }

      it 'is refused instead of raising' do
        expect(subject.errors.first).to include('n’existe pas dans le brouillon')
      end
    end
  end

  describe '#move_type_de_champ_checked' do
    subject { draft.move_type_de_champ_checked(target, after_stable_id: after) }

    let(:target) { stable_id('boursier') }
    let(:after) { nil }

    it 'moves first without a position' do
      expect(subject).to be_success
      expect(subject.stable_id).to eq(target.to_s)
      expect(libelles).to eq(['boursier', 'age', 'enfants'])
    end

    context 'after another type de champ' do
      let(:target) { stable_id('age') }
      let(:after) { stable_id('boursier') }

      it do
        expect(subject).to be_success
        expect(libelles).to eq(['enfants', 'boursier', 'age'])
      end
    end

    context 'in a repetition' do
      before { draft.add_type_de_champ({ type_champ: 'text', libelle: 'nom', parent_stable_id: stable_id('enfants') }) }

      let(:target) { stable_id('nom') }
      let(:after) { stable_id('prénom') }

      it do
        expect(subject).to be_success
        expect(child('enfants').flat_children.map(&:libelle)).to eq(['prénom', 'nom'])
      end

      context 'first without a position' do
        let(:target) { stable_id('prénom') }
        let(:after) { nil }

        it do
          expect(subject).to be_success
          expect(child('enfants').flat_children.map(&:libelle)).to eq(['prénom', 'nom'])
        end
      end
    end

    context 'with the stable id of nowhere' do
      let(:target) { 0 }

      it { expect(subject.errors.first).to include('n’existe pas dans le brouillon') }
    end

    context 'after a champ of nowhere' do
      let(:after) { 'abc' }

      it { expect(subject.errors).to eq(["Le champ « abc » n’existe pas dans le brouillon de cette démarche."]) }
    end

    context 'after itself' do
      let(:after) { target }

      it { expect(subject.errors.first).to include('après lui-même') }
    end

    context 'after itself written with leading zeros' do
      let(:after) { "0#{target}" }

      it 'is still after itself' do
        expect(subject.errors.first).to include('après lui-même')
        expect(libelles).to eq(['age', 'enfants', 'boursier'])
      end
    end

    context 'after a private annotation' do
      before { draft.add_type_de_champ({ type_champ: 'text', libelle: 'note', private: true }) }

      let(:after) { stable_id('note') }

      it 'is refused' do
        expect(subject.errors.first).to include('n’est pas dans le même bloc')
        expect(libelles).to eq(['age', 'enfants', 'boursier'])
      end
    end

    context 'after a champ of another block' do
      let(:after) { stable_id('prénom') }

      it 'is refused' do
        expect(subject.errors.first).to include('n’est pas dans le même bloc')
        expect(libelles).to eq(['age', 'enfants', 'boursier'])
      end
    end

    context 'when the source of a condition is moved after the champ it conditions' do
      before { child('boursier').update!(condition: equals(stable_id('age'))) }

      let(:target) { stable_id('age') }
      let(:after) { stable_id('boursier') }

      it 'is refused and the order is unchanged' do
        expect(subject).not_to be_success
        expect(subject.errors.first).to include('« boursier »')
        expect(libelles).to eq(['age', 'enfants', 'boursier'])
      end

      it 'leaves the revision in memory as in the database' do
        subject
        expect(draft.public_root_type_de_champs.map(&:libelle)).to eq(['age', 'enfants', 'boursier'])
      end

      it 'rolls back inside an enclosing transaction too' do
        ActiveRecord::Base.transaction do
          expect(subject).not_to be_success
          expect(libelles).to eq(['age', 'enfants', 'boursier'])
        end
      end
    end

    context 'when the champ conditioned is moved before its source' do
      before { child('boursier').update!(condition: equals(stable_id('age'))) }

      it 'is refused' do
        expect(subject.errors.first).to include('« boursier »')
        expect(libelles).to eq(['age', 'enfants', 'boursier'])
      end
    end

    context 'when the condition was already broken' do
      before { child('boursier').update!(condition: equals(stable_id('age'))) }

      let(:target) { stable_id('enfants') }
      let(:after) { stable_id('boursier') }

      it 'does not hold a move that changes nothing against it' do
        draft.move_type_de_champ(stable_id('age'), 2)
        expect(subject).to be_success
      end
    end

    context 'when a champ has no libelle' do
      before { draft.type_de_champs.find { it.libelle == 'age' }.update_columns(libelle: '') }

      context 'and it is moved after another one' do
        let(:target) { draft.type_de_champs.find { it.libelle == '' }.stable_id }
        let(:after) { stable_id('boursier') }

        it do
          expect(subject).to be_success
          expect(libelles).to eq(['enfants', 'boursier', ''])
        end
      end

      context 'and another one is moved across it' do
        let(:after) { nil }

        it do
          expect(subject).to be_success
          expect(libelles).to eq(['boursier', '', 'enfants'])
        end
      end
    end

    context 'when the procedure is published meanwhile' do
      before { draft.update_columns(published_at: Time.zone.now) }

      it { expect(subject.errors.first).to include('n’existe pas dans le brouillon') }
    end
  end

  describe '#update_type_de_champ_checked' do
    subject { draft.update_type_de_champ_checked(stable_id('age'), **params) }

    let(:params) { { libelle: 'âge', description: 'en années', mandatory: false } }

    it 'updates the type de champ' do
      expect(subject).to be_success
      expect(child('âge')).to have_attributes(description: 'en années', mandatory: false)
    end

    context 'with options' do
      let(:params) { { options: { min_number: '0' } } }

      it 'keeps the options it does not mention' do
        draft.update_type_de_champ_checked(stable_id('age'), options: { max_number: '120' })

        expect(subject).to be_success
        expect(child('age').options).to include('min_number' => '0', 'max_number' => '120')
      end
    end

    context 'with an option the type does not have' do
      let(:params) { { options: { character_limit: '4' } } }

      it { expect(subject.errors.first).to include('character_limit') }
    end

    context 'with a type of the matrix' do
      let(:params) { { type_champ: 'decimal_number' } }

      it 'changes the type' do
        expect(subject).to be_success
        expect(child('age').type_champ).to eq('decimal_number')
      end
    end

    context 'with a type and its options at once' do
      let(:params) { { type_champ: 'integer_number', options: { min_number: '1' } } }

      it { expect(subject).to be_success }
    end

    context 'with a type outside the matrix of a published champ' do
      let(:params) { { type_champ: 'yes_no' } }

      before do
        procedure.publish!(procedure.administrateurs.first)
        procedure.reload
      end

      it 'is refused and the type stays' do
        expect(subject.errors.first).to include('« age »', 'integer_number', 'decimal_number')
        expect(child('age').type_champ).to eq('integer_number')
      end
    end

    context 'with an unknown type' do
      let(:params) { { type_champ: 'telepathy' } }

      it { expect(subject.errors).to eq([I18n.t('activerecord.errors.models.procedure_revision.draft_edit.unknown_type_champ', type_champ: 'telepathy')]) }
    end

    context 'with a repetition that holds a child' do
      subject { draft.update_type_de_champ_checked(stable_id('enfants'), type_champ: 'text') }

      it 'is refused and the child stays' do
        expect(subject.errors.first).to include('« enfants »')
        expect(child('enfants').type_champ).to eq('repetition')
        expect(child('prénom').stable_id).to be_present
      end
    end

    context 'with a carte, whose options are merged' do
      let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :carte, libelle: 'plan' }]) }

      it 'keeps the layer set before' do
        draft.update_type_de_champ_checked(stable_id('plan'), options: { cadastres: true })

        expect(draft.update_type_de_champ_checked(stable_id('plan'), options: { unesco: true })).to be_success
        expect(child('plan').options).to include('cadastres' => true, 'unesco' => true)
      end
    end

    context 'with a text turned into a repetition' do
      subject { draft.update_type_de_champ_checked(stable_id('nom'), type_champ: 'repetition') }

      let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :text, libelle: 'nom' }]) }

      it 'succeeds, the repetition being empty' do
        expect(subject).to be_success
        expect(child('nom').type_champ).to eq('repetition')
      end
    end

    context 'with a header section' do
      let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :header_section, libelle: 'titre' }]) }

      [{ mandatory: true }, { description: 'x' }].each do |params|
        it "refuses #{params.keys.first} and saves nothing" do
          result = draft.update_type_de_champ_checked(stable_id('titre'), **params)

          expect(result).not_to be_success
          expect(child('titre')).to have_attributes(mandatory: false)
          expect(child('titre').description).not_to eq('x')
        end
      end
    end

    context 'with a mandatory flag against the constraints of the type' do
      let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :text, libelle: 'nom' }]) }

      it 'refuses a text turned into a header section that is mandatory' do
        result = draft.update_type_de_champ_checked(stable_id('nom'), type_champ: 'header_section', mandatory: true)

        expect(result.errors.first).to include('header_section')
        expect(child('nom').type_champ).to eq('text')
      end
    end

    context 'when the type de champ is locked by a routing rule' do
      let(:params) { { type_champ: 'decimal_number' } }

      before do
        procedure.defaut_groupe_instructeur.update!(routing_rule: Logic::Eq.new(Logic::ChampValue.new(stable_id('age')), Logic::Constant.new('18')))
        procedure.reload
      end

      it 'refuses the type only' do
        expect(subject.errors.first).to include('age')
        expect(draft.update_type_de_champ_checked(stable_id('age'), libelle: 'âge')).to be_success
      end

      it 'accepts options the rule does not read' do
        expect(draft.update_type_de_champ_checked(stable_id('age'), options: { max_number: '120' })).to be_success
        expect(child('age').options).to include('max_number' => '120')
      end
    end

    context 'when a drop-down list is read by an eligibility rule' do
      let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :drop_down_list, libelle: 'ville', options: ['Paris', 'Lyon'] }]) }
      let(:ville) { stable_id('ville') }
      let(:refused) { I18n.t('activerecord.errors.models.procedure_revision.draft_edit.options_read_by_rules', libelle: 'ville') }

      before do
        draft.update!(ineligibilite_enabled: true, ineligibilite_message: 'non', ineligibilite_rules: Logic::Eq.new(Logic::ChampValue.new(ville), Logic::Constant.new('Paris')))
      end

      it 'refuses to remove a choice' do
        result = draft.update_type_de_champ_checked(ville, options: { drop_down_options: ['Paris'] })

        expect(result.errors).to eq([refused])
        expect(child('ville').drop_down_options).to eq(['Paris', 'Lyon'])
      end

      it 'accepts an added choice and an unchanged list' do
        expect(draft.update_type_de_champ_checked(ville, options: { drop_down_options: ['Paris', 'Lyon', 'Nice'] })).to be_success
        expect(draft.update_type_de_champ_checked(ville, options: { drop_down_options: ['Paris', 'Lyon', 'Nice'] })).to be_success
      end

      it 'still refuses when the field is also in a referentiel url' do
        allow_any_instance_of(Procedure).to receive(:used_by_referentiel_urls?).and_return(true)

        expect(draft.update_type_de_champ_checked(ville, options: { drop_down_options: ['13', '69'] }).errors).to eq([refused])
      end
    end

    context 'when the change breaks a condition' do
      let(:params) { { type_champ: 'yes_no' } }

      before { child('boursier').update!(condition: equals(stable_id('age'))) }

      it 'is undone' do
        expect(subject).not_to be_success
        expect(child('age').type_champ).to eq('integer_number')
      end
    end

    context 'with nothing to change' do
      let(:params) { {} }

      it { expect(subject.errors).to eq([I18n.t('activerecord.errors.models.procedure_revision.draft_edit.nothing_to_update')]) }
    end

    context 'with a stable id of nowhere' do
      subject { draft.update_type_de_champ_checked('0', libelle: 'x') }

      it { expect(subject.errors.first).to include('n’existe pas') }
    end

    context 'when the procedure is published meanwhile' do
      before { draft.update_columns(published_at: Time.zone.now) }

      it { expect(subject.errors).to eq([I18n.t('activerecord.errors.models.procedure_revision.draft_edit.revision_published')]) }
    end
  end

  describe '#add_type_de_champ_checked' do
    let(:params) { { type_champ: 'text', libelle: 'nom' } }

    subject { draft.add_type_de_champ_checked(**params) }

    it 'adds first in the form without a position' do
      expect(subject).to be_success
      expect(subject.stable_id).to eq(stable_id('nom').to_s)
      expect(libelles).to eq(['nom', 'age', 'enfants', 'boursier'])
    end

    context 'with a position' do
      let(:params) { super().merge(after_stable_id: stable_id('age').to_s) }

      it { expect { subject }.to change { libelles }.to(['age', 'nom', 'enfants', 'boursier']) }
    end

    context 'in a repetition' do
      let(:params) { super().merge(parent_stable_id: stable_id('enfants'), after_stable_id: stable_id('prénom')) }

      it 'adds it after the sibling' do
        expect(subject).to be_success
        expect(child('enfants').flat_children.map(&:libelle)).to eq(['prénom', 'nom'])
      end
    end

    context 'with a parent that is not a repetition' do
      let(:params) { super().merge(parent_stable_id: stable_id('age')) }

      it { expect(subject.errors.first).to include('« age »', 'pas un bloc répétable') }
    end

    context 'with a position in another block' do
      let(:params) { super().merge(after_stable_id: stable_id('prénom')) }

      it { expect(subject.errors.first).to include('même bloc') }
    end

    context 'with a position of nowhere' do
      let(:params) { super().merge(after_stable_id: '0') }

      it { expect(subject.errors.first).to include('n’existe pas dans le brouillon') }
    end

    context 'with an unknown type' do
      let(:params) { super().merge(type_champ: 'formule') }

      it { expect(subject.errors).to eq(['Le type de champ « formule » n’existe pas.']) }
    end

    context 'with a repetition inside a repetition' do
      let(:params) { super().merge(type_champ: 'repetition', parent_stable_id: stable_id('enfants')) }

      it { expect(subject.errors.first).to include('bloc répétable') }
    end

    context 'with a type behind a feature flag' do
      let(:params) { super().merge(type_champ: 'engagement_juridique', private: true) }

      it { expect(subject.errors.first).to include('n’est pas activé') }

      it 'is accepted once the flag is enabled' do
        Flipper.enable(:engagement_juridique_type_de_champ, procedure)

        expect(subject).to be_success
      end
    end

    context 'with a type of the annotations in the form' do
      let(:params) { super().merge(type_champ: 'engagement_juridique') }

      before { Flipper.enable(:engagement_juridique_type_de_champ, procedure) }

      it { expect(subject.errors.first).to include('annotations privées') }
    end

    context 'with options' do
      let(:params) { { type_champ: 'drop_down_list', libelle: 'couleur', options: { drop_down_options: ['rouge', ' vert '], drop_down_other: true } } }

      it 'goes through the writers of the type' do
        expect(subject).to be_success
        expect(child('couleur').drop_down_options).to eq(['rouge', 'vert'])
        expect(child('couleur')).to be_drop_down_other
      end
    end

    context 'with the options of another type' do
      let(:params) { { type_champ: 'textarea', libelle: 'motivation', options: { max_number: 3 } } }

      it 'is refused, naming the accepted options' do
        expect(subject.errors.first).to include('max_number', 'character_limit')
        expect(libelles).not_to include('motivation')
      end
    end

    context 'with an option the editor does not offer' do
      let(:params) { { type_champ: 'piece_justificative', libelle: 'rib', options: { skip_pj_validation: true } } }

      it { expect(subject.errors.first).to include('skip_pj_validation') }
    end

    context 'with options that are not an object' do
      let(:params) { super().merge(options: ['a']) }

      it { expect(subject.errors).to eq(['Les options doivent être un objet (clé/valeur).']) }
    end

    context 'with a type without option' do
      let(:params) { super().merge(options: { character_limit: 10 }) }

      it { expect(subject.errors.first).to include('Options acceptées : aucune') }
    end

    context 'with the layers of a carte' do
      let(:params) { { type_champ: 'carte', libelle: 'parcelle', options: { cadastres: true, unesco: true, znieff: true } } }

      it 'keeps every layer' do
        expect(subject).to be_success
        expect(child('parcelle').carte_optional_layers).to eq([:cadastres, :unesco, :znieff])
      end
    end

    context 'with a header section level that does not exist' do
      let(:params) { { type_champ: 'header_section', libelle: 'titre', options: { header_section_level: '9' } } }

      it 'is refused and nothing is added' do
        expect(subject).not_to be_success
        expect(libelles).not_to include('titre')
      end

      it 'is accepted within the levels' do
        draft.add_type_de_champ_checked(type_champ: 'header_section', libelle: 'chapitre', options: { header_section_level: 1 })

        expect(draft.add_type_de_champ_checked(**params, after_stable_id: stable_id('chapitre').to_s, options: { header_section_level: 2 })).to be_success
        expect(child('titre').header_section_level).to eq(2)
      end
    end

    describe 'mandatory' do
      it 'is left to the column default when absent' do
        subject

        expect(child('nom')).to be_mandatory
      end

      it 'is kept when given' do
        draft.add_type_de_champ_checked(**params, mandatory: false)

        expect(child('nom')).not_to be_mandatory
      end

      context 'with a header section, which cannot be filled' do
        let(:params) { { type_champ: 'header_section', libelle: 'titre' } }

        it 'is not mandatory, even when asked' do
          draft.add_type_de_champ_checked(**params, mandatory: true)

          expect(child('titre')).not_to be_mandatory
        end
      end

      context 'with a type that must be mandatory' do
        let(:procedure) { create(:procedure, :with_api_particulier_token) }
        let(:params) { { type_champ: 'quotient_familial', libelle: 'qf' } }

        it 'is mandatory, even when refused' do
          result = draft.add_type_de_champ_checked(**params, mandatory: false)

          expect(draft.reload.type_de_champ(result.stable_id)).to be_mandatory
        end
      end

      context 'in the annotations' do
        let(:params) { super().merge(private: true) }

        it 'is not mandatory' do
          subject

          expect(child('nom')).to be_private
          expect(child('nom')).not_to be_mandatory
        end
      end
    end

    context 'with a formatted type de champ' do
      let(:params) { { type_champ: 'formatted', libelle: 'code', options: { max_character_length: 5 } } }

      it 'completes the options given with the defaults' do
        expect(subject).to be_success
        expect(child('code')).to have_attributes(formatted_mode: 'simple', max_character_length: 5)
        expect(child('code')).to be_letters_accepted
      end
    end

    context 'with a type that the editor shows invalid once added' do
      let(:params) { { type_champ: 'integer_number', libelle: 'montant', options: { range_number: true, min_number: 10, max_number: 1 } } }

      it 'is refused and not kept' do
        expect(subject).not_to be_success
        expect(libelles).not_to include('montant')
      end
    end

    context 'when a repetition is added' do
      let(:params) { { type_champ: 'repetition', libelle: 'dépenses' } }

      it 'is accepted empty' do
        expect(subject).to be_success
        expect(draft.reload.type_de_champ(subject.stable_id)).to be_repetition
      end

      it 'is refused when its range is inconsistent' do
        params[:options] = { limit_repetitions: true, min_repetitions: 5, max_repetitions: 2 }
        expect(subject).not_to be_success
        expect(libelles).not_to include('dépenses')
        expect(draft.reload.type_de_champs.map(&:libelle)).not_to include('dépenses')
      end

      it 'is refused when limited without bounds' do
        params[:options] = { limit_repetitions: true }
        expect(subject).not_to be_success
        expect(draft.reload.type_de_champs.map(&:libelle)).not_to include('dépenses')
      end
    end

    context 'when the draft is published meanwhile' do
      before { draft.update_columns(published_at: Time.zone.now) }

      it { expect(subject.errors).to eq(['Le brouillon vient d’être publié : il n’est plus modifiable.']) }
    end

    context 'with an annotation in a public repetition' do
      let(:params) { { type_champ: 'text', libelle: 'note', private: true, parent_stable_id: stable_id('enfants') } }

      it 'is refused and nothing is added' do
        expect(subject).not_to be_success
        expect(subject.errors.first).to include('enfants')
        expect(draft.reload.type_de_champs.map(&:libelle)).not_to include('note')
      end
    end

    context 'with the privacy omitted in a private repetition' do
      let(:params) { { type_champ: 'text', libelle: 'note', parent_stable_id: stable_id('suivi') } }

      before do
        parent = draft.add_type_de_champ({ type_champ: 'repetition', libelle: 'suivi', private: true })
        draft.add_type_de_champ({ type_champ: 'text', libelle: 'ancien', private: true, parent_stable_id: parent.stable_id })
      end

      it 'follows the block' do
        expect(subject).to be_success
        expect(child('note')).to be_private
      end
    end
  end
end
