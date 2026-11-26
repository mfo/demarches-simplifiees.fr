# frozen_string_literal: true

# The instance methods need a laid-out instance obtained from a revision,
# as `type_champ_locked?` does.
module TypeDeChampTypeChangeConcern
  extend ActiveSupport::Concern

  ACCEPTED_TYPE_CHANGES = Columns::ChampColumn::CAST.keys
    .group_by { |(from)| from.to_s }
    .transform_values { |pairs| pairs.map { |(_, to)| to.to_s }.freeze }
    .freeze

  class_methods do
    # Types the editor offers: feature flags, repetition and public/private
    # restrictions applied. Usable before any field exists.
    def available_types(procedure:, private:, in_repetition:)
      type_champ_classes
        .filter { it.feature_flag.nil? || procedure.feature_enabled?(it.feature_flag) }
        .filter { !in_repetition || it.allowed_in_repetition? }
        .filter { private ? !it.public_only? : !it.private_only? }
    end
  end

  def available_types
    self.class.available_types(procedure: revision.procedure, private: private?, in_repetition: in_repetition?)
  end

  # A field of the published revision only converts along ACCEPTED_TYPE_CHANGES,
  # so the filed dossiers stay readable; any other field accepts every type.
  def accepted_type_champs
    published_type_champ = revision.procedure.published_revision&.type_de_champ(stable_id)&.type_champ

    if published_type_champ.present?
      ([published_type_champ] + ACCEPTED_TYPE_CHANGES.fetch(published_type_champ, [])).uniq
    else
      TypeDeChamp.type_champs.keys
    end
  end

  # The lock (`type_champ_locked?`) is checked separately: it has its own message.
  def can_become?(new_type_champ)
    type_champ = new_type_champ.to_s
    accepted_type_champs.include?(type_champ) && available_types.any? { it.sti_name == type_champ }
  end
end
