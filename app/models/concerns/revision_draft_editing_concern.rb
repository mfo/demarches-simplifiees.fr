# frozen_string_literal: true

# The draft edits made on behalf of a programmatic client (GraphQL mutations):
# the guards of the types de champ editor, and refusals worded for the client.
module RevisionDraftEditingConcern
  extend ActiveSupport::Concern

  Result = Data.define(:stable_id, :errors) do
    def self.success(stable_id) = new(stable_id: stable_id.to_s, errors: [])
    def self.failure(*errors) = new(stable_id: nil, errors: errors.flatten)

    def success? = errors.empty?
  end

  # The type de champ of a stable id given by a client: nil when it is not an
  # integer or not in this revision.
  def find_type_de_champ_to_edit(stable_id)
    id = Integer(stable_id.to_s, 10, exception: false)
    type_de_champ(id) if id
  end

  # Removes a type de champ (and the children of a repetition) unless the
  # editor would refuse, or leave a condition pointing at it.
  def remove_type_de_champ_checked(stable_id)
    type_de_champ = find_type_de_champ_to_edit(stable_id)
    return draft_edit_not_found(stable_id) if type_de_champ.nil?
    return Result.failure(type_de_champ.deletion_locked_message) if type_de_champ.type_champ_locked?

    dependents = type_de_champs_conditioned_on(type_de_champ)
    return draft_edit_dependent_conditions(type_de_champ, dependents) if dependents.present?

    remove_type_de_champ(type_de_champ.stable_id).present? ? Result.success(type_de_champ.stable_id) : draft_edit_not_found(stable_id)
  rescue ActiveRecord::RecordNotFound # the revision got published meanwhile
    draft_edit_not_found(stable_id)
  end

  private

  # Not dependent_conditions: it only scans the root types de champ, so it would
  # miss repetition children and public champs conditioned on an annotation.
  def type_de_champs_conditioned_on(type_de_champ)
    type_de_champs.filter { it.condition? && it.condition.sources.include?(type_de_champ.stable_id) }
  end

  def draft_edit_not_found(stable_id)
    Result.failure(I18n.t('activerecord.errors.models.procedure_revision.draft_edit.not_found', stable_id:))
  end

  def draft_edit_dependent_conditions(type_de_champ, dependents)
    libelles = dependents.map { I18n.t('activerecord.errors.models.procedure_revision.draft_edit.dependent', libelle: it.libelle, stable_id: it.stable_id) }.to_sentence
    Result.failure(I18n.t('activerecord.errors.models.procedure_revision.draft_edit.dependent_conditions', type_de_champ: type_de_champ.libelle, dependents: libelles))
  end
end
