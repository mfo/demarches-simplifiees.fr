# frozen_string_literal: true

module RevisionComparisonConcern
  extend ActiveSupport::Concern

  def compare_type_de_champs(revision)
    changes = []
    changes += compare_revision_type_de_champs(revision_type_de_champs, revision.revision_type_de_champs)
    changes
  end

  def compare_ineligibilite_rules(revision)
    changes = []
    changes += compare_revision_ineligibilite_rules(revision)
    changes
  end

  private

  def compare_revision_type_de_champs(from_coordinates, to_coordinates)
    if from_coordinates == to_coordinates
      []
    else
      from_h = from_coordinates.index_by(&:stable_id)
      to_h = to_coordinates.index_by(&:stable_id)

      from_sids = from_h.keys
      to_sids = to_h.keys

      removed = (from_sids - to_sids).map { ProcedureRevisionChange::RemoveChamp.new(from_h[_1]) }
      added = (to_sids - from_sids).map { ProcedureRevisionChange::AddChamp.new(to_h[_1]) }

      kept = from_sids.intersection(to_sids)

      moved = kept
        .map { [from_h[_1], to_h[_1]] }
        .filter { |from, to| from.position != to.position }
        .map { |from, to| ProcedureRevisionChange::MoveChamp.new(from, from.position, to.position) }

      changed = kept
        .map { [from_h[_1], to_h[_1]] }
        .flat_map { |from, to| compare_type_de_champ(from.type_de_champ, to.type_de_champ, from_coordinates, to_coordinates) }

      (removed + added + moved + changed).sort_by { _1.op == :remove ? from_sids.index(_1.stable_id) : to_sids.index(_1.stable_id) }
    end
  end

  def compare_revision_ineligibilite_rules(new_revision)
    from_ineligibilite_rules = ineligibilite_rules
    to_ineligibilite_rules = new_revision.ineligibilite_rules
    changes = []

    if from_ineligibilite_rules.present? && to_ineligibilite_rules.blank?
      changes << ProcedureRevisionChange::RemoveEligibiliteRuleChange
    end
    if from_ineligibilite_rules.blank? && to_ineligibilite_rules.present?
      changes << ProcedureRevisionChange::AddEligibiliteRuleChange
    end
    if from_ineligibilite_rules != to_ineligibilite_rules
      changes << ProcedureRevisionChange::UpdateEligibiliteRuleChange
    end
    if ineligibilite_message != new_revision.ineligibilite_message
      changes << ProcedureRevisionChange::UpdateEligibiliteMessageChange
    end
    if ineligibilite_enabled != new_revision.ineligibilite_enabled
      changes << (new_revision.ineligibilite_enabled ? ProcedureRevisionChange::EligibiliteEnabledChange : ProcedureRevisionChange::EligibiliteDisabledChange)
    end
    changes.map { _1.new(self, new_revision) }
  end

  def compare_type_de_champ(from_type_de_champ, to_type_de_champ, from_coordinates, to_coordinates)
    changes = []
    if from_type_de_champ.type_champ != to_type_de_champ.type_champ
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :type_champ,
        from_type_de_champ.type_champ,
        to_type_de_champ.type_champ)
      # the options are compared as the new type reads them
      from_type_de_champ = from_type_de_champ.becomes_type(to_type_de_champ.type_champ)
    end
    if from_type_de_champ.libelle != to_type_de_champ.libelle
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :libelle,
        from_type_de_champ.libelle,
        to_type_de_champ.libelle)
    end
    if from_type_de_champ.description != to_type_de_champ.description
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :description,
        from_type_de_champ.description,
        to_type_de_champ.description)
    end
    if from_type_de_champ.mandatory? != to_type_de_champ.mandatory?
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :mandatory,
        from_type_de_champ.mandatory?,
        to_type_de_champ.mandatory?)
    end

    if from_type_de_champ.condition != to_type_de_champ.condition
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :condition,
        from_type_de_champ.condition&.to_s(from_coordinates.map(&:type_de_champ)),
        to_type_de_champ.condition&.to_s(to_coordinates.map(&:type_de_champ)))
    end

    if to_type_de_champ.any_drop_down_list?
      if from_type_de_champ.drop_down_mode != to_type_de_champ.drop_down_mode
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :drop_down_mode,
          from_type_de_champ.drop_down_mode,
          to_type_de_champ.drop_down_mode)
      end

      if to_type_de_champ.drop_down_advanced?
        if from_type_de_champ.referentiel_id != to_type_de_champ.referentiel_id
          changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
            :referentiel,
            from_type_de_champ.referentiel_id,
            to_type_de_champ.referentiel_id)
        end
      else
        from_drop_down_options = from_type_de_champ.drop_down_advanced? ? [] : from_type_de_champ.drop_down_options
        if from_drop_down_options != to_type_de_champ.drop_down_options
          changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
            :drop_down_options,
            from_drop_down_options,
            to_type_de_champ.drop_down_options)
        end
      end

      if to_type_de_champ.linked_drop_down_list?
        if from_type_de_champ.drop_down_secondary_libelle != to_type_de_champ.drop_down_secondary_libelle
          changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
            :drop_down_secondary_libelle,
            from_type_de_champ.drop_down_secondary_libelle,
            to_type_de_champ.drop_down_secondary_libelle)
        end
        if from_type_de_champ.drop_down_secondary_description != to_type_de_champ.drop_down_secondary_description
          changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
            :drop_down_secondary_description,
            from_type_de_champ.drop_down_secondary_description,
            to_type_de_champ.drop_down_secondary_description)
        end
      end

      if from_type_de_champ.drop_down_other? != to_type_de_champ.drop_down_other?
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :drop_down_other,
          from_type_de_champ.drop_down_other?,
          to_type_de_champ.drop_down_other?)
      end
    elsif to_type_de_champ.carte?
      if from_type_de_champ.carte_optional_layers != to_type_de_champ.carte_optional_layers
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :carte_layers,
          from_type_de_champ.carte_optional_layers,
          to_type_de_champ.carte_optional_layers)
      end
    elsif to_type_de_champ.piece_justificative?
      if from_type_de_champ.piece_justificative_template.blob&.checksum != to_type_de_champ.piece_justificative_template.blob&.checksum
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :piece_justificative_template,
          from_type_de_champ.piece_justificative_template.blob&.filename,
          to_type_de_champ.piece_justificative_template.blob&.filename)
      end
      if from_type_de_champ.nature != to_type_de_champ.nature
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :nature,
          from_type_de_champ.nature,
          to_type_de_champ.nature)
      end

      # titre d'identité, RIB, justificatif de domicile et avis d'impôt ont des règles spécifiques, pas besoin de comparer les limit de pj (tous limite a 1), les format (tous du scan, et de comparer l'autopurge)
      if [to_type_de_champ, from_type_de_champ].none? { |it| it.titre_identite? || it.rib? || it.justificatif_domicile? || it.avis_impot? }
        if from_type_de_champ.pj_limit_formats != to_type_de_champ.pj_limit_formats
          changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
            :pj_limit_formats,
            from_type_de_champ.pj_limit_formats,
            to_type_de_champ.pj_limit_formats)
        end
        if Array.wrap(from_type_de_champ.pj_format_families) != Array.wrap(to_type_de_champ.pj_format_families)
          changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
            :pj_format_families,
            from_type_de_champ.pj_format_families,
            to_type_de_champ.pj_format_families)
        end
        if from_type_de_champ.pj_auto_purge != to_type_de_champ.pj_auto_purge
          changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
            :pj_auto_purge,
            from_type_de_champ.pj_auto_purge,
            to_type_de_champ.pj_auto_purge)
        end
      end
    elsif to_type_de_champ.explication?
      if from_type_de_champ.notice_explicative.blob&.checksum != to_type_de_champ.notice_explicative.blob&.checksum
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :notice_explicative,
          from_type_de_champ.notice_explicative.blob&.filename,
          to_type_de_champ.notice_explicative.blob&.filename)
      end
      if from_type_de_champ.collapsible_explanation_enabled? != to_type_de_champ.collapsible_explanation_enabled?
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :collapsible_explanation_enabled,
          from_type_de_champ.collapsible_explanation_enabled?,
          to_type_de_champ.collapsible_explanation_enabled?)
      end
      if from_type_de_champ.collapsible_explanation_text != to_type_de_champ.collapsible_explanation_text
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :collapsible_explanation_text,
          from_type_de_champ.collapsible_explanation_text,
          to_type_de_champ.collapsible_explanation_text)
      end
    elsif to_type_de_champ.textarea?
      if from_type_de_champ.character_limit.presence != to_type_de_champ.character_limit.presence
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :character_limit,
          from_type_de_champ.character_limit,
          to_type_de_champ.character_limit)
      end
    elsif to_type_de_champ.integer_number? || to_type_de_champ.decimal_number?
      if from_type_de_champ.positive_number != to_type_de_champ.positive_number
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :positive_number,
          from_type_de_champ.positive_number,
          to_type_de_champ.positive_number)
      end
      if from_type_de_champ.range_number != to_type_de_champ.range_number
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :range_number,
          from_type_de_champ.range_number,
          to_type_de_champ.range_number)
      end
      if from_type_de_champ.min_number != to_type_de_champ.min_number
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :min_number,
          from_type_de_champ.min_number,
          to_type_de_champ.min_number)
      end
      if from_type_de_champ.max_number != to_type_de_champ.max_number
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :max_number,
          from_type_de_champ.max_number,
          to_type_de_champ.max_number)
      end
    elsif to_type_de_champ.date? || to_type_de_champ.datetime?
      if from_type_de_champ.range_date != to_type_de_champ.range_date
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :range_date,
          from_type_de_champ.range_date,
          to_type_de_champ.range_date)
      end
      if from_type_de_champ.date_in_past != to_type_de_champ.date_in_past
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :date_in_past,
          from_type_de_champ.date_in_past,
          to_type_de_champ.date_in_past)
      end
      if from_type_de_champ.start_date != to_type_de_champ.start_date
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :start_date,
          from_type_de_champ.start_date,
          to_type_de_champ.start_date)
      end
      if from_type_de_champ.end_date != to_type_de_champ.end_date
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :end_date,
          from_type_de_champ.end_date,
          to_type_de_champ.end_date)
      end
    elsif to_type_de_champ.formatted?
      if from_type_de_champ.expression_reguliere != to_type_de_champ.expression_reguliere
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :expression_reguliere,
          from_type_de_champ.expression_reguliere,
          to_type_de_champ.expression_reguliere)
      end
      if from_type_de_champ.expression_reguliere_indications != to_type_de_champ.expression_reguliere_indications
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :expression_reguliere_indications,
          from_type_de_champ.expression_reguliere_indications,
          to_type_de_champ.expression_reguliere_indications)
      end
      if from_type_de_champ.expression_reguliere_exemple_text != to_type_de_champ.expression_reguliere_exemple_text
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :expression_reguliere_exemple_text,
          from_type_de_champ.expression_reguliere_exemple_text,
          to_type_de_champ.expression_reguliere_exemple_text)
      end
      if from_type_de_champ.expression_reguliere_error_message != to_type_de_champ.expression_reguliere_error_message
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :expression_reguliere_error_message,
          from_type_de_champ.expression_reguliere_error_message,
          to_type_de_champ.expression_reguliere_error_message)
      end
      if from_type_de_champ.formatted_mode != to_type_de_champ.formatted_mode
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :formatted_mode,
          from_type_de_champ.formatted_mode,
          to_type_de_champ.formatted_mode)
      end
      if from_type_de_champ.letters_accepted != to_type_de_champ.letters_accepted
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :letters_accepted,
          from_type_de_champ.letters_accepted,
          to_type_de_champ.letters_accepted)
      end
      if from_type_de_champ.numbers_accepted != to_type_de_champ.numbers_accepted
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :numbers_accepted,
          from_type_de_champ.numbers_accepted,
          to_type_de_champ.numbers_accepted)
      end
      if from_type_de_champ.special_characters_accepted != to_type_de_champ.special_characters_accepted
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :special_characters_accepted,
          from_type_de_champ.special_characters_accepted,
          to_type_de_champ.special_characters_accepted)
      end
      if from_type_de_champ.min_character_length != to_type_de_champ.min_character_length
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :min_character_length,
          from_type_de_champ.min_character_length,
          to_type_de_champ.min_character_length)
      end
      if from_type_de_champ.max_character_length != to_type_de_champ.max_character_length
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :max_character_length,
          from_type_de_champ.max_character_length,
          to_type_de_champ.max_character_length)
      end
    elsif to_type_de_champ.repetition?
      if from_type_de_champ.limit_repetitions != to_type_de_champ.limit_repetitions
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :limit_repetitions,
          from_type_de_champ.limit_repetitions,
          to_type_de_champ.limit_repetitions)
      end
      if from_type_de_champ.min_repetitions != to_type_de_champ.min_repetitions
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :min_repetitions,
          from_type_de_champ.min_repetitions,
          to_type_de_champ.min_repetitions)
      end
      if from_type_de_champ.max_repetitions != to_type_de_champ.max_repetitions
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :max_repetitions,
          from_type_de_champ.max_repetitions,
          to_type_de_champ.max_repetitions)
      end
    elsif to_type_de_champ.referentiel?
      compare_referentiel_changes(from_type_de_champ, to_type_de_champ).each do |change|
        changes << change
      end
    elsif to_type_de_champ.dossier_link?
      if from_type_de_champ.procedures_limit != to_type_de_champ.procedures_limit
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :procedures_limit,
          from_type_de_champ.procedures_limit,
          to_type_de_champ.procedures_limit)
      end
      if from_type_de_champ.dossier_link_procedure_ids != to_type_de_champ.dossier_link_procedure_ids
        all_ids = (from_type_de_champ.dossier_link_procedure_ids + to_type_de_champ.dossier_link_procedure_ids).uniq
        procedures_by_id = Procedure.with_discarded.where(id: all_ids).pluck(:id, :libelle).to_h
        from = from_type_de_champ.dossier_link_procedure_ids.map { { id: _1, libelle: procedures_by_id[_1] } }
        to = to_type_de_champ.dossier_link_procedure_ids.map { { id: _1, libelle: procedures_by_id[_1] } }
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :dossier_link_procedure_ids,
          from,
          to)
      end
    end
    changes
  end

  def compare_referentiel_changes(from_type_de_champ, to_type_de_champ)
    changes = []
    from_referentiel = from_type_de_champ.referentiel
    to_referentiel = to_type_de_champ.referentiel

    [:url_tiptap, :mode, :hint, :test_data_tiptap].each do |field|
      if from_referentiel&.send(field) != to_referentiel&.send(field)
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          "referentiel_#{field}".to_sym,
          from_referentiel&.send(field),
          to_referentiel&.send(field))
      end
    end

    if from_type_de_champ.referentiel_mapping != to_type_de_champ.referentiel_mapping
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :referentiel_mapping,
        from_type_de_champ.referentiel_mapping,
        to_type_de_champ.referentiel_mapping)
    end

    changes
  end
end
