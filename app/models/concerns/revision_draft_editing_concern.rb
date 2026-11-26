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

  # Moves a type de champ right after another one of the same block, or first
  # in its block without one. Undone when it breaks a condition or another rule
  # of the editor.
  def move_type_de_champ_checked(stable_id, after_stable_id: nil)
    type_de_champ = find_type_de_champ_to_edit(stable_id)
    return draft_edit_not_found(stable_id) if type_de_champ.nil?

    after = nil
    if after_stable_id.present?
      after = find_type_de_champ_to_edit(after_stable_id)
      return draft_edit_not_found(after_stable_id) if after.nil?
      return draft_edit_failure(:moved_after_itself, libelle: type_de_champ.libelle) if after.stable_id == type_de_champ.stable_id
      return draft_edit_failure(:other_block, stable_id: after.stable_id) if type_de_champ.flat_siblings.none? { it.stable_id == after.stable_id }
    end

    apply_draft_edit_unless_new_errors do
      moved = after ? move_type_de_champ_after(type_de_champ.stable_id, after.stable_id) : move_type_de_champ(type_de_champ.stable_id, 0)
      moved.present? ? Result.success(type_de_champ.stable_id) : draft_edit_not_found(stable_id)
    end
  rescue ActiveRecord::RecordNotFound # the revision got published meanwhile
    draft_edit_not_found(stable_id)
  end

  # Runs an edit returning a Result and keeps it only if the editor shows no
  # error more than before: the editor lets an edit break a rule and shows it
  # broken, a client that does not look at the form afterwards is told instead.
  def apply_draft_edit_unless_new_errors
    errors_before = draft_editor_error_keys
    result = nil
    undone = false

    transaction(requires_new: true) do
      result = yield
      next if !result.success?

      introduced = procedure.draft_editor_errors_by_stable_id.values.flatten.reject { draft_editor_error_key(it).in?(errors_before) }
      next if introduced.empty?

      result = Result.failure(introduced.map { draft_edit_introduced_error(it) })
      undone = true
      raise ActiveRecord::Rollback
    end

    reload if undone # it has seen an edit the database has not kept
    result
  end

  private

  def draft_editor_error_keys
    procedure.draft_editor_errors_by_stable_id.values.flatten.to_set { draft_editor_error_key(it) }
  end

  def draft_editor_error_key(error) = [error.options[:type_de_champ].stable_id, error.attribute, error.type]

  def draft_edit_introduced_error(error)
    type_de_champ = error.options[:type_de_champ]
    draft_edit_t(:introduced_error, libelle: type_de_champ.libelle, stable_id: type_de_champ.stable_id, message: error.message)
  end

  def draft_edit_failure(key, **) = Result.failure(draft_edit_t(key, **))

  def draft_edit_t(key, **) = I18n.t("activerecord.errors.models.procedure_revision.draft_edit.#{key}", **)

  # Not dependent_conditions: it only scans the root types de champ, so it would
  # miss repetition children and public champs conditioned on an annotation.
  def type_de_champs_conditioned_on(type_de_champ)
    type_de_champs.filter { it.condition? && it.condition.sources.include?(type_de_champ.stable_id) }
  end

  def draft_edit_not_found(stable_id) = draft_edit_failure(:not_found, stable_id:)

  def draft_edit_dependent_conditions(type_de_champ, dependents)
    libelles = dependents.map { draft_edit_t(:dependent, libelle: it.libelle, stable_id: it.stable_id) }.to_sentence
    draft_edit_failure(:dependent_conditions, type_de_champ: type_de_champ.libelle, dependents: libelles)
  end
end
