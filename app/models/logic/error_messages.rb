# frozen_string_literal: true

# The wording of the errors Logic.errors finds in a condition, for whoever
# shows them: the editor (Conditions::ConditionsErrorsComponent) or an API.
class Logic::ErrorMessages
  def initialize(condition, source_tdcs)
    @condition, @source_tdcs = condition, source_tdcs
  end

  def to_a
    errors = @condition ? Logic.errors(@condition, @source_tdcs).uniq : []

    # if a tdc is not available (has been removed for example)
    # it causes a lot of errors (incompatible type for example)
    # only the root cause is displayed
    if errors.include?({ type: :not_available })
      [I18n.t('logic.error_messages.not_available')]
    else
      errors.filter_map { humanize(it) }
    end
  end

  private

  def humanize(error)
    case error
    in { type: :not_available }
    in { type: :incompatible, stable_id: nil }
      I18n.t('logic.error_messages.not_available')
    in { type: :unmanaged, stable_id: stable_id }
      targeted_champ = source_tdc(stable_id)
      I18n.t('logic.error_messages.unmanaged',
        libelle: targeted_champ.libelle,
        type_champ: I18n.t(targeted_champ.type_champ, scope: 'activerecord.attributes.type_de_champ.type_champs')&.downcase)
    in { type: :incompatible, stable_id: stable_id, right: right, operator_name: operator_name }
      targeted_champ = source_tdc(stable_id)
      I18n.t('logic.error_messages.incompatible',
        libelle: targeted_champ.libelle,
        type_champ: I18n.t(targeted_champ.type_champ, scope: 'activerecord.attributes.type_de_champ.type_champs')&.downcase,
        operator: I18n.t(operator_name, scope: 'logic.operators').downcase,
        right: right.to_s.downcase)
    in { type: :required_number, operator_name: operator_name }
      I18n.t('logic.error_messages.required_number',
        operator: I18n.t(operator_name, scope: 'logic.operators'))
    in { type: :not_included, stable_id: stable_id, right: right }
      targeted_champ = source_tdc(stable_id)
      I18n.t('logic.error_messages.not_included',
        libelle: targeted_champ.libelle,
        right: right.to_s.downcase)
    in { type: :required_list }
      I18n.t('logic.error_messages.required_list')
    in { type: :required_include, operator_name: "Logic::Eq" }
      I18n.t('logic.error_messages.required_include.eq')
    in { type: :required_include, operator_name: "Logic::NotEq" }
      I18n.t('logic.error_messages.required_include.not_eq')
    in { type: :empty_options, stable_id: stable_id }
      targeted_champ = source_tdc(stable_id)
      I18n.t('logic.error_messages.empty_options',
        libelle: targeted_champ.libelle)
    in { type: :contradiction, stable_id: stable_id, comparisons: comparisons, limits: limits, branch: true }
      targeted_champ = source_tdc(stable_id)
      I18n.t('logic.error_messages.limited_branch',
        count: comparisons.size,
        libelle: targeted_champ.libelle,
        comparisons: comparisons.map { humanize_comparison(it) }.to_sentence,
        limits: humanize_limits(limits))
    in { type: :contradiction, stable_id: stable_id, comparisons: comparisons, branch: true }
      targeted_champ = source_tdc(stable_id)
      I18n.t('logic.error_messages.contradiction_branch',
        count: comparisons.size,
        libelle: targeted_champ.libelle,
        comparisons: comparisons.map { humanize_comparison(it) }.to_sentence)
    in { type: :contradiction, stable_id: stable_id, comparisons: comparisons, limits: limits }
      targeted_champ = source_tdc(stable_id)
      I18n.t('logic.error_messages.limited',
        count: comparisons.size,
        libelle: targeted_champ.libelle,
        comparisons: comparisons.map { humanize_comparison(it) }.to_sentence,
        limits: humanize_limits(limits))
    in { type: :contradiction, stable_id: stable_id, comparisons: comparisons }
      targeted_champ = source_tdc(stable_id)
      I18n.t('logic.error_messages.contradiction',
        count: comparisons.size,
        libelle: targeted_champ.libelle,
        comparisons: comparisons.map { humanize_comparison(it) }.to_sentence)
    in { type: :unreachable, stable_id: stable_id, branch: true }
      targeted_champ = source_tdc(stable_id)
      I18n.t('logic.error_messages.unreachable_branch', libelle: targeted_champ.libelle)
    in { type: :unreachable, stable_id: stable_id }
      targeted_champ = source_tdc(stable_id)
      I18n.t('logic.error_messages.unreachable', libelle: targeted_champ.libelle)
    else
      nil
    end
  end

  def source_tdc(stable_id) = @source_tdcs.find { it.stable_id == stable_id }

  def humanize_limits(limits)
    case limits
    in { min: Numeric => min, max: Numeric => max }
      I18n.t('logic.error_messages.limits.between', min: humanize_number(min), max: humanize_number(max))
    in { min: Numeric => min }
      I18n.t('logic.error_messages.limits.min', min: humanize_number(min))
    in { max: Numeric => max }
      I18n.t('logic.error_messages.limits.max', max: humanize_number(max))
    end
  end

  # A decimal bound typed as a whole number reads as one
  def humanize_number(number) = (number.is_a?(Float) && number == number.to_i ? number.to_i : number).to_s

  # A row as the editor reads it, the champ aside: « est dans la région Bretagne »
  def humanize_comparison(comparison)
    I18n.t('logic.error_messages.comparison', comparison: "#{operator_label(comparison).downcase} #{humanize_value(comparison)}")
  end

  # The label the editor gives the operator (see
  # ConditionsComponent#compatibles_operators_for_select): « est » and
  # « n’est pas » for anything but a number
  def operator_label(comparison)
    case comparison
    when Logic::NotEq then I18n.t('is_not', scope: 'logic')
    when Logic::Eq
      comparison.left.type(@source_tdcs) == :number ? I18n.t(comparison.class.name, scope: 'logic.operators') : I18n.t('is', scope: 'logic')
    else I18n.t(comparison.class.name, scope: 'logic.operators')
    end
  end

  # The label the admin picked (a region name, a departement, a choice) rather
  # than the value stored behind it
  def humanize_value(comparison)
    label, _value = comparison.left.options(@source_tdcs, comparison.class.name)&.find { |_label, value| value == comparison.right.value }

    label || comparison.right.to_s.downcase
  end
end
