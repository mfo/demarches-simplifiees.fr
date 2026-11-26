# frozen_string_literal: true

module TypeDeChampTypeChangeConcern
  extend ActiveSupport::Concern

  ACCEPTED_TYPE_CHANGES = Columns::ChampColumn::CAST.keys
    .group_by { |(from)| from.to_s }
    .transform_values { |pairs| pairs.map { |(_, to)| to.to_s } }

  # Types the editor offers for this field: feature flags, repetition and
  # public/private restrictions applied.
  def available_types
    TypeDeChamp.type_champ_classes
      .filter { it.feature_flag.nil? || procedure.feature_enabled?(it.feature_flag) }
      .filter { !in_repetition? || it.allowed_in_repetition? }
      .filter { private? ? !it.public_only? : !it.private_only? }
  end

  # Once the procedure is published, a field only converts along the
  # ACCEPTED_TYPE_CHANGES matrix; before that, any type is accepted.
  def accepted_type_champs
    published_type_champ = procedure.published_revision&.type_de_champs&.find { it.stable_id == stable_id }&.type_champ

    if published_type_champ.present?
      ([published_type_champ] + ACCEPTED_TYPE_CHANGES.fetch(published_type_champ, [])).uniq
    else
      TypeDeChamp.type_champs.keys
    end
  end

  def can_become?(new_type_champ)
    accepted_type_champs.include?(new_type_champ.to_s)
  end
end
