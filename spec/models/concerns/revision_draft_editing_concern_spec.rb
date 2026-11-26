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

      let(:target) { stable_id('prénom') }
      let(:after) { stable_id('nom') }

      it do
        expect(subject).to be_success
        expect(child('enfants').flat_children.map(&:libelle)).to eq(['nom', 'prénom'])
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

    context 'when the procedure is published meanwhile' do
      before { draft.update_columns(published_at: Time.zone.now) }

      it { expect(subject.errors.first).to include('n’existe pas dans le brouillon') }
    end
  end
end
