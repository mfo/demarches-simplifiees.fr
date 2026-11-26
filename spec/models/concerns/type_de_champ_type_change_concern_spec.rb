# frozen_string_literal: true

describe TypeDeChampTypeChangeConcern do
  describe 'ACCEPTED_TYPE_CHANGES' do
    it 'contains expected conversions' do
      expect(described_class::ACCEPTED_TYPE_CHANGES).to include(
        "checkbox" => ["yes_no", "text", "textarea", "formatted"],
        "civilite" => ["text", "textarea", "formatted"],
        "communes" => ["text", "textarea", "formatted"],
        "date" => ["datetime", "text", "textarea", "formatted"],
        "datetime" => ["date", "text", "textarea", "formatted"],
        "decimal_number" => ["integer_number", "text", "textarea", "formatted"],
        "drop_down_list" => ["multiple_drop_down_list", "text", "textarea", "formatted", "pre_rempli"],
        "email" => ["text", "textarea", "formatted"],
        "formatted" => ["textarea", "text", "email", "phone", "pre_rempli"],
        "integer_number" => ["decimal_number", "text", "textarea", "formatted"],
        "multiple_drop_down_list" => ["drop_down_list", "text", "textarea", "formatted"],
        "phone" => ["text", "textarea", "formatted"],
        "pre_rempli" => ["text", "textarea", "formatted", "drop_down_list"],
        "text" => ["textarea", "formatted", "email", "phone", "decimal_number", "integer_number", "pre_rempli"],
        "textarea" => ["text", "formatted", "pre_rempli"],
        "yes_no" => ["checkbox", "text", "textarea", "formatted"]
      )
    end
  end

  describe 'available types' do
    let_it_be(:procedure) { create(:procedure, public_type_de_champs: [{ type: :text }], private_type_de_champs: [{ type: :text }]) }
    let_it_be(:repetition_procedure) { create(:procedure, public_type_de_champs: [{ type: :repetition, children: [{ type: :text }] }]) }
    let(:public_tdc) { procedure.draft_revision.public_root_type_de_champs.first }
    let(:private_tdc) { procedure.draft_revision.private_root_type_de_champs.first }

    it 'hides public-only types on a private field and private-only ones on a public field' do
      Flipper.enable_actor(:engagement_juridique_type_de_champ, procedure)

      expect(public_tdc.available_types.map(&:sti_name)).to include('quotient_familial')
      expect(public_tdc.available_types.map(&:sti_name)).not_to include('engagement_juridique')
      expect(private_tdc.available_types.map(&:sti_name)).to include('engagement_juridique')
      expect(private_tdc.available_types.map(&:sti_name)).not_to include('quotient_familial')
    end

    it 'hides types behind a disabled feature flag' do
      expect(private_tdc.available_types.map(&:sti_name)).not_to include('engagement_juridique')
    end

    it 'hides types not allowed in a repetition' do
      child = repetition_procedure.draft_revision.public_root_type_de_champs.first.children.first

      expect(child.available_types.map(&:sti_name)).not_to include('repetition', 'quotient_familial')
    end

    it 'lists the offered types before any field exists' do
      Flipper.enable_actor(:engagement_juridique_type_de_champ, procedure)

      names = -> (**args) { TypeDeChamp.available_types(procedure:, **args).map(&:sti_name) }

      expect(names.call(private: true, in_repetition: false)).to include('engagement_juridique')
      expect(names.call(private: false, in_repetition: false)).to include('quotient_familial', 'repetition')
      expect(names.call(private: false, in_repetition: true)).not_to include('repetition')
    end

    it 'can_become? also requires the type to be offered' do
      Flipper.enable_actor(:engagement_juridique_type_de_champ, procedure)
      child = repetition_procedure.draft_revision.public_root_type_de_champs.first.children.first

      expect(public_tdc.can_become?('engagement_juridique')).to be(false)
      expect(private_tdc.can_become?('engagement_juridique')).to be(true)
      expect(child.can_become?('repetition')).to be(false)
    end
  end

  describe '#accepted_type_champs and #can_become?' do
    let_it_be(:published) { create(:procedure, :published, public_type_de_champs: [{ type: :date }]) }
    let_it_be(:unpublished) { create(:procedure, public_type_de_champs: [{ type: :date }]) }
    let_it_be(:piece_procedure) { create(:procedure, :published, public_type_de_champs: [{ type: :piece_justificative }]) }
    let(:fresh_published) { Procedure.find(published.id) }
    let(:tdc) { fresh_published.draft_revision.public_root_type_de_champs.first }

    it 'follows the matrix for a field of the published revision' do
      expect(tdc.accepted_type_champs).to eq(['date', 'datetime', 'text', 'textarea', 'formatted'])
      expect(tdc.can_become?(:datetime)).to be(true)
      expect(tdc.can_become?('text')).to be(true)
      expect(tdc.can_become?('integer_number')).to be(false)
    end

    it 'accepts every type while the procedure is a draft' do
      tdc = unpublished.draft_revision.public_root_type_de_champs.first

      expect(tdc.accepted_type_champs).to match_array(TypeDeChamp.type_champs.keys)
      expect(tdc.can_become?('integer_number')).to be(true)
    end

    it 'accepts every type for a field added after publication' do
      added = fresh_published.draft_revision.add_type_de_champ(type_champ: :date, libelle: 'x')
      tdc = fresh_published.draft_revision.type_de_champ(added.stable_id)

      expect(tdc.accepted_type_champs).to match_array(TypeDeChamp.type_champs.keys)
    end

    it 'only accepts itself when no conversion exists' do
      tdc = piece_procedure.draft_revision.public_root_type_de_champs.first

      expect(tdc.accepted_type_champs).to eq(['piece_justificative'])
    end
  end
end
