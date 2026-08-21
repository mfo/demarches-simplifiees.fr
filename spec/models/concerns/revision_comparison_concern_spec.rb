# frozen_string_literal: true

describe RevisionComparisonConcern do
  # Builds a procedure with one public type de champ (`from`), applies `to`
  # to it in a new draft and returns the changes between the two revisions.
  def compare(type, from: {}, to: {})
    procedure = create(:procedure, public_type_de_champs: [{ type:, libelle: 'champ', **from }])
    new_draft = procedure.create_new_revision
    stable_id = procedure.active_revision.public_root_type_de_champs.first.stable_id
    type_de_champ = new_draft.find_and_ensure_exclusive_use(stable_id)
    yield type_de_champ if block_given?
    type_de_champ = type_de_champ.becomes_type(to[:type_champ]) if to[:type_champ].present?
    type_de_champ.update!(to)
    procedure.active_revision.compare_type_de_champs(new_draft.reload).map(&:to_h)
  end

  def update(attribute, from, to)
    a_hash_including(op: :update, attribute:, from:, to:)
  end

  def filename(name)
    name.nil? ? nil : an_object_having_attributes(to_s: name)
  end

  # Each row: [type, from attributes, to attributes, expected change]. Every
  # row must produce exactly that one change: the table also guards against
  # spurious diffs on untouched options.
  def expect_single_changes(rows)
    aggregate_failures do
      rows.each do |type, from, to, expected|
        expect(compare(type, from:, to:)).to contain_exactly(expected), "#{type} #{from} -> #{to}"
      end
    end
  end

  describe '#compare_type_de_champs' do
    it 'diffs the attributes common to every type de champ' do
      expect_single_changes([
        [:text, {}, { libelle: 'new' }, update(:libelle, 'champ', 'new')],
        [:text, { description: 'old' }, { description: 'new' }, update(:description, 'old', 'new')],
        [:text, { mandatory: false }, { mandatory: true }, update(:mandatory, false, true)],
        [:text, {}, { type_champ: :integer_number }, update(:type_champ, 'text', 'integer_number')],
      ])
    end

    it 'reads the options of the previous version as the new type' do
      expect(compare(:text, to: { type_champ: :drop_down_list, drop_down_options: ['a'] }))
        .to contain_exactly(update(:type_champ, 'text', 'drop_down_list'), update(:drop_down_options, [], ['a']))
    end

    it 'diffs textarea options' do
      expect_single_changes([
        [:textarea, {}, { character_limit: '400' }, update(:character_limit, nil, '400')],
        [:textarea, { character_limit: '400' }, { character_limit: '' }, update(:character_limit, '400', '')],
      ])
      expect(compare(:textarea, to: { character_limit: '' })).to be_empty
    end

    it 'diffs number options' do
      expect_single_changes([
        [:integer_number, { positive_number: '0' }, { positive_number: '1' }, update(:positive_number, '0', '1')],
        [:integer_number, { range_number: '0' }, { range_number: '1' }, update(:range_number, '0', '1')],
        [:integer_number, { range_number: '1', min_number: '1' }, { min_number: '2' }, update(:min_number, '1', '2')],
        [:decimal_number, { range_number: '1', max_number: '9' }, { max_number: '' }, update(:max_number, '9', '')],
      ])
    end

    it 'diffs date options' do
      expect_single_changes([
        [:date, { range_date: '0' }, { range_date: '1' }, update(:range_date, '0', '1')],
        [:date, { date_in_past: '0' }, { date_in_past: '1' }, update(:date_in_past, '0', '1')],
        [:date, { range_date: '1', start_date: '2024-01-01' }, { start_date: '2025-01-01' }, update(:start_date, '2024-01-01', '2025-01-01')],
        [:datetime, { range_date: '1', end_date: '2024-01-01' }, { end_date: '' }, update(:end_date, '2024-01-01', '')],
      ])
    end

    it 'diffs formatted options' do
      simple = { formatted_mode: 'simple', letters_accepted: '1', numbers_accepted: '1', special_characters_accepted: '1' }
      advanced = { formatted_mode: 'advanced', expression_reguliere: '[a-z]+', expression_reguliere_exemple_text: 'abc' }

      expect_single_changes([
        [:formatted, simple, { letters_accepted: '0' }, update(:letters_accepted, '1', '0')],
        [:formatted, simple, { numbers_accepted: '0' }, update(:numbers_accepted, '1', '0')],
        [:formatted, simple, { special_characters_accepted: '0' }, update(:special_characters_accepted, '1', '0')],
        [:formatted, simple, { min_character_length: '2' }, update(:min_character_length, nil, '2')],
        [:formatted, simple, { max_character_length: '9' }, update(:max_character_length, nil, '9')],
        [:formatted, simple, { formatted_mode: 'advanced' }, update(:formatted_mode, 'simple', 'advanced')],
        [:formatted, advanced, { expression_reguliere: '[a-c]+' }, update(:expression_reguliere, '[a-z]+', '[a-c]+')],
        [:formatted, advanced, { expression_reguliere_exemple_text: 'xyz' }, update(:expression_reguliere_exemple_text, 'abc', 'xyz')],
        [:formatted, advanced, { expression_reguliere_indications: 'lowercase' }, update(:expression_reguliere_indications, nil, 'lowercase')],
        [:formatted, advanced, { expression_reguliere_error_message: 'nope' }, update(:expression_reguliere_error_message, nil, 'nope')],
      ])
    end

    it 'diffs repetition options' do
      expect_single_changes([
        [:repetition, { limit_repetitions: '0' }, { limit_repetitions: '1' }, update(:limit_repetitions, '0', '1')],
        [:repetition, { limit_repetitions: '1', min_repetitions: '1' }, { min_repetitions: '2' }, update(:min_repetitions, '1', '2')],
        [:repetition, { limit_repetitions: '1', max_repetitions: '3' }, { max_repetitions: '4' }, update(:max_repetitions, '3', '4')],
      ])
    end

    it 'diffs drop-down list options' do
      expect_single_changes([
        [:drop_down_list, { options: ['a'] }, { drop_down_options: ['a', 'b'] }, update(:drop_down_options, ['a'], ['a', 'b'])],
        [:drop_down_list, { options: ['a'] }, { drop_down_other: '1' }, update(:drop_down_other, false, true)],
        [:multiple_drop_down_list, { options: ['a'] }, { drop_down_options: ['b'] }, update(:drop_down_options, ['a'], ['b'])],
        [:linked_drop_down_list, { options: ['--a--', 'b'] }, { drop_down_secondary_libelle: 'sub' }, update(:drop_down_secondary_libelle, nil, 'sub')],
        [:linked_drop_down_list, { options: ['--a--', 'b'] }, { drop_down_secondary_description: 'sub' }, update(:drop_down_secondary_description, nil, 'sub')],
      ])
    end

    context 'with an advanced drop-down list' do
      let(:referentiel_1) { create(:csv_referentiel, :with_items) }
      let(:referentiel_2) { create(:csv_referentiel, :with_items) }

      it 'compares the referentiel instead of the options' do
        expect(compare(:drop_down_list, from: { drop_down_mode: 'advanced', referentiel: referentiel_1 }, to: { referentiel: referentiel_2 }))
          .to contain_exactly(update(:referentiel, referentiel_1.id, referentiel_2.id))
      end

      it 'reports the switch from simple to advanced' do
        expect(compare(:drop_down_list, from: { options: ['a'] }, to: { drop_down_mode: 'advanced', referentiel: referentiel_1 }))
          .to contain_exactly(update(:drop_down_mode, nil, 'advanced'), update(:referentiel, nil, referentiel_1.id), update(:drop_down_options, ['a'], []))
      end
    end

    it 'diffs the enabled carte layers as one change' do
      expect(compare(:carte, to: { options: { unesco: '1', znieff: '1' } })).to contain_exactly(update(:carte_layers, [], [:unesco, :znieff]))
    end

    it 'diffs piece justificative options' do
      expect_single_changes([
        [:piece_justificative, {}, { nature: 'rib' }, update(:nature, nil, 'rib')],
        [:piece_justificative, { pj_limit_formats: '0' }, { pj_limit_formats: '1' }, update(:pj_limit_formats, '0', '1')],
        [:piece_justificative, { pj_limit_formats: '1' }, { pj_format_families: ['image'] }, update(:pj_format_families, [], ['image'])],
        [:piece_justificative, { pj_auto_purge: '0' }, { pj_auto_purge: '1' }, update(:pj_auto_purge, '0', '1')],
      ])
    end

    it 'ignores the format options of the natures that force them' do
      expect(compare(:piece_justificative, from: { nature: 'rib' }, to: { pj_auto_purge: '1' })).to be_empty
    end

    it 'compares attachments by content and reports their filename' do
      attach = -> (attachment, name) { attachment.attach(io: StringIO.new(name), filename: name, content_type: 'text/plain', metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }) }

      template_changes = compare(:piece_justificative) { attach.call(it.piece_justificative_template, 'tata.txt') }
      notice_changes = compare(:explication) { attach.call(it.notice_explicative, 'notice.txt') }

      expect(template_changes).to contain_exactly(update(:piece_justificative_template, filename('toto.txt'), filename('tata.txt')))
      expect(notice_changes).to contain_exactly(update(:notice_explicative, nil, filename('notice.txt')))
    end

    it 'diffs explication options' do
      expect_single_changes([
        [:explication, {}, { collapsible_explanation_enabled: '1' }, update(:collapsible_explanation_enabled, false, true)],
        [:explication, { collapsible_explanation_enabled: '1' }, { collapsible_explanation_text: 'more' }, update(:collapsible_explanation_text, nil, 'more')],
      ])
    end

    it 'diffs referentiel and dossier link options' do
      referentiel = create(:api_referentiel, :exact_match)

      expect_single_changes([
        [:referentiel, { referentiel:, referentiel_mapping: { a: 1 } }, { referentiel_mapping: { a: 2 } }, update(:referentiel_mapping, { 'a' => 1 }, { 'a' => 2 })],
        [:dossier_link, { procedures_limit: '0' }, { procedures_limit: '1' }, update(:procedures_limit, '0', '1')],
      ])
    end

    it 'diffs header section, birthdate and pre rempli options' do
      expect_single_changes([
        [:header_section, { level: '1' }, { header_section_level: '2' }, update(:header_section_level, '1', '2')],
        [:date, { birthdate: '0' }, { birthdate: '1' }, update(:birthdate, '0', '1')],
        [:date, { birthdate: '1', prefill_with_france_connect_information: '0' }, { prefill_with_france_connect_information: '1' }, update(:prefill_with_france_connect_information, '0', '1')],
        [:pre_rempli, {}, { pre_rempli_hidden: '1' }, update(:pre_rempli_hidden, false, true)],
        [:pre_rempli, {}, { drop_down_options: ['a'] }, update(:drop_down_options, [], ['a'])],
      ])
    end
  end

  describe 'TypeDeChamp#revision_diff_attributes' do
    # Editable options that are, on purpose, not diffed one by one.
    let(:not_diffed) do
      {
        carte: TypesDeChamp::CarteTypeDeChamp::LAYERS, # aggregated as :carte_layers
        piece_justificative: [:old_pj, :skip_pj_validation, :skip_content_type_pj_validation], # legacy, not editable
      }
    end

    it 'covers every editable option of every type de champ' do
      aggregate_failures do
        TypeDeChamp.type_champs.each_key do |type_champ|
          klass = TypeDeChamp.find_sti_class(type_champ)
          diffed = klass.new.revision_diff_attributes(nil).keys
          expected = klass.option_keys - not_diffed.fetch(type_champ.to_sym, [])

          expect(expected - diffed).to be_empty, "#{type_champ} does not diff #{expected - diffed}"
        end
      end
    end
  end
end
