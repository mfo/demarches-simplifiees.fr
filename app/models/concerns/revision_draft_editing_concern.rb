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

  # Options the editor form does not offer either: internal switches, and the
  # mapping of a referentiel, which has an editor of its own.
  HIDDEN_OPTIONS = [:old_pj, :skip_pj_validation, :skip_content_type_pj_validation, :referentiel_mapping].freeze

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

  # Adds a type de champ first in its block, or after a sibling, unless the
  # editor would not offer the type there. `mandatory` is left out when nil, so
  # that the constraints of the type and the default of the column apply.
  def add_type_de_champ_checked(type_champ:, libelle:, description: nil, mandatory: nil, private: nil, parent_stable_id: nil, after_stable_id: nil, options: nil)
    return draft_edit_failure(:unknown_type_champ, type_champ:) if !TypeDeChamp.type_champs.value?(type_champ)

    parent = find_type_de_champ_to_edit(parent_stable_id) if parent_stable_id.present?
    if parent_stable_id.present?
      return draft_edit_not_found(parent_stable_id) if parent.nil?
      return draft_edit_failure(:not_a_repetition, libelle: parent.libelle) if !parent.repetition?

      return draft_edit_failure(:parent_other_form, libelle: parent.libelle) if !private.nil? && private != parent.private?

      private = parent.private?
    else
      private = private.present?
    end

    klass = TypeDeChamp.find_sti_class(type_champ)
    errors = draft_edit_type_champ_errors(klass, private:, in_repetition: parent.present?)
    errors = draft_edit_option_errors(klass, options) if errors.empty?
    return Result.failure(errors) if errors.present?

    if after_stable_id.present?
      after = find_type_de_champ_to_edit(after_stable_id)
      return draft_edit_not_found(after_stable_id) if after.nil?
      return draft_edit_failure(:other_block, stable_id: after.stable_id) if after.enclosing_repetition&.stable_id != parent&.stable_id || after.private? != private
    end

    params = { type_champ:, libelle:, description:, mandatory:, private:, parent_stable_id: parent&.stable_id, after_stable_id: after&.stable_id }.compact

    # a repetition is added empty: its first child cannot exist before it
    added = nil
    empty_repetition = -> do
      tdc = it.options[:type_de_champ]
      tdc.stable_id == added&.stable_id && it.type == procedure.errors.generate_message(it.attribute, :empty_repetition, { value: tdc.libelle })
    end

    apply_draft_edit_unless_new_errors(tolerated: empty_repetition) do
      added = type_de_champ = add_type_de_champ(draft_edit_option_params(klass, options).merge(params))

      if type_de_champ.persisted? && type_de_champ.errors.empty?
        Result.success(type_de_champ.stable_id)
      elsif published_at? # reloaded by the lock: the draft was published meanwhile
        draft_edit_failure(:revision_published)
      else
        Result.failure(type_de_champ.errors.full_messages)
      end
    end
  end

  # Changes the label, description, mandatory flag, type and options of a type
  # de champ. The options not given are kept. Refused where the editor would
  # not offer the change, and where it would silently break what reads the champ.
  def update_type_de_champ_checked(stable_id, libelle: nil, description: nil, mandatory: nil, type_champ: nil, options: nil)
    type_de_champ = find_type_de_champ_to_edit(stable_id)
    return draft_edit_not_found(stable_id) if type_de_champ.nil?

    changing_type = type_champ.present? && type_champ != type_de_champ.type_champ
    errors = changing_type ? draft_edit_type_change_errors(type_de_champ, type_champ) : []
    klass = TypeDeChamp.find_sti_class(changing_type ? type_champ : type_de_champ.type_champ) if errors.empty?
    errors = draft_edit_option_errors(klass, options) if errors.empty?
    errors = draft_edit_read_options_errors(type_de_champ, options) if errors.empty?
    return Result.failure(errors) if errors.present?

    params = { libelle:, description:, mandatory: }.compact
    return draft_edit_failure(:nothing_to_update) if params.empty? && options.blank? && !changing_type

    apply_draft_edit_unless_new_errors do
      type_de_champ = find_and_ensure_exclusive_use(type_de_champ.stable_id)
      type_de_champ = type_de_champ.becomes_type(type_champ) if changing_type
      params[:type_champ] = type_champ if changing_type
      params = draft_edit_option_params(klass, options, current: type_de_champ.options).merge(params)

      if update_type_de_champ(type_de_champ, params)
        Result.success(type_de_champ.stable_id)
      else
        Result.failure(type_de_champ.errors.full_messages)
      end
    end
  rescue ActiveRecord::RecordNotFound # the revision got published meanwhile
    draft_edit_not_found(stable_id)
  end

  # Runs an edit returning a Result and keeps it only if the editor shows no
  # error more than before: the editor lets an edit break a rule and shows it
  # broken, a client that does not look at the form afterwards is told instead.
  # `tolerated` tells the new errors that are expected after this very edit.
  def apply_draft_edit_unless_new_errors(tolerated: nil)
    errors_before = draft_editor_error_keys
    result = nil
    undone = false

    transaction(requires_new: true) do
      result = yield
      next if !result.success?

      introduced = procedure.draft_editor_errors_by_stable_id.values.flatten.reject { draft_editor_error_key(it).in?(errors_before) || tolerated&.call(it) }
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

  def draft_editable_option_keys(klass) = klass.option_keys - HIDDEN_OPTIONS

  # What the type selector of the editor filters out of its menu.
  def draft_edit_type_champ_errors(klass, private:, in_repetition:)
    return [] if TypeDeChamp.available_types(procedure:, private:, in_repetition:).include?(klass)

    reason = if klass.feature_flag.present? && !procedure.feature_enabled?(klass.feature_flag)
      :type_champ_disabled
    elsif in_repetition && !klass.allowed_in_repetition?
      :type_champ_not_in_repetition
    elsif private
      :type_champ_not_private
    else
      :type_champ_private_only
    end

    [draft_edit_t(reason, type_champ: klass.sti_name)]
  end

  # The matrix of the type selector, which keeps the answers of the dossiers
  # already filed readable, then what the selector offers there.
  def draft_edit_type_change_errors(type_de_champ, type_champ)
    return [draft_edit_t(:unknown_type_champ, type_champ:)] if !TypeDeChamp.type_champs.value?(type_champ)
    return [type_de_champ.type_change_locked_message] if type_de_champ.type_champ_locked?
    return [draft_edit_t(:repetition_not_empty, libelle: type_de_champ.libelle)] if type_de_champ.repetition? && type_de_champ.children.present?

    accepted = type_de_champ.accepted_type_champs
    return [draft_edit_t(:type_change_published, libelle: type_de_champ.libelle, accepted: accepted.join(', '))] if !accepted.include?(type_champ)

    draft_edit_type_champ_errors(TypeDeChamp.find_sti_class(type_champ), private: type_de_champ.private?, in_repetition: type_de_champ.in_repetition?)
  end

  # The editor does not check the rules of routing and of ineligibility against
  # the options they were written for (the values of a list).
  def draft_edit_read_options_errors(type_de_champ, options)
    return [] if options.blank?
    return [] if !type_de_champ.type_champ_lock_reason.in?([:used_by_routing_rules, :used_by_ineligibilite_rules])

    [draft_edit_t(:options_read_by_rules, libelle: type_de_champ.libelle)]
  end

  def draft_edit_option_errors(klass, options)
    return [] if options.blank?
    return [draft_edit_t(:options_not_an_object)] if !options.respond_to?(:to_h) || options.is_a?(Array)

    allowed = draft_editable_option_keys(klass).map(&:to_s)
    unknown = options.to_h.keys.map(&:to_s) - allowed
    return [] if unknown.empty?

    [draft_edit_t(:unknown_options, type_champ: klass.sti_name, unknown: unknown.join(', '), allowed: allowed.presence&.join(', ') || draft_edit_t(:no_option))]
  end

  # The options go through the writers of the type, as the editor form sends
  # them. A type reading some of its options from the jsonb without a writer
  # (the layers of a carte) gets them all merged there, as its own editor does.
  def draft_edit_option_params(klass, options, current: {})
    return {} if options.blank?

    options = options.to_h.transform_keys(&:to_sym)

    if klass.option_keys.all? { klass.method_defined?(:"#{it}=") }
      options
    else
      { options: (current || {}).to_h.merge(options.stringify_keys) }
    end
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
