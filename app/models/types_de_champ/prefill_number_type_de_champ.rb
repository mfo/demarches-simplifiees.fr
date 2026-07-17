# frozen_string_literal: true

class TypesDeChamp::PrefillNumberTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  private

  def screened_value(champ, value)
    return nil if !scalar_prefill_value?(value)

    formatted_value = NumberFormatValidator.normalize(value, decimal: decimal_number?)
    return nil if formatted_value.blank?
    return nil if NumberFormatValidator.violations(formatted_value, decimal: decimal_number?).any?
    return nil if NumberLimitValidator.violations(formatted_value, self).any?

    formatted_value
  end
end
