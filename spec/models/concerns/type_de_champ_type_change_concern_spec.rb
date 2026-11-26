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

  describe '#available_types' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :text }], private_type_de_champs: [{ type: :text }]) }
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
      procedure = create(:procedure, public_type_de_champs: [{ type: :repetition, children: [{ type: :text }] }])
      child = procedure.draft_revision.public_root_type_de_champs.first.children.first

      expect(child.available_types.map(&:sti_name)).not_to include('repetition', 'quotient_familial')
    end
  end

  describe '#accepted_type_champs and #can_become?' do
    let(:procedure) { create(:procedure, :published, public_type_de_champs: [{ type: :date }]) }
    let(:tdc) { procedure.draft_revision.public_root_type_de_champs.first }

    it 'follows the matrix once the procedure is published' do
      expect(tdc.accepted_type_champs).to eq(['date', 'datetime', 'text', 'textarea', 'formatted'])
      expect(tdc.can_become?(:datetime)).to be(true)
      expect(tdc.can_become?('text')).to be(true)
      expect(tdc.can_become?('integer_number')).to be(false)
    end

    it 'accepts every type while the procedure is a draft' do
      tdc = create(:procedure, public_type_de_champs: [{ type: :date }]).draft_revision.public_root_type_de_champs.first

      expect(tdc.accepted_type_champs).to match_array(TypeDeChamp.type_champs.keys)
      expect(tdc.can_become?('integer_number')).to be(true)
    end

    it 'only accepts itself when no conversion exists' do
      procedure = create(:procedure, :published, public_type_de_champs: [{ type: :piece_justificative }])
      tdc = procedure.draft_revision.public_root_type_de_champs.first

      expect(tdc.accepted_type_champs).to eq(['piece_justificative'])
    end
  end
end
