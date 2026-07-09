# frozen_string_literal: true

class TypesDeChamp::PrefillMultipleDropDownListTypeDeChamp < TypesDeChamp::PrefillDropDownListTypeDeChamp
  def example_value
    return nil if all_possible_values.empty?
    return all_possible_values.first if all_possible_values.one?

    [all_possible_values.first, all_possible_values.second]
  end

  private

  def screened_value(champ, value)
    return nil if !acceptable_prefill_value?(value)

    values = Champs::MultipleDropDownListChamp.parse_values(value)
    return nil if DropDownOptionsValidator.violations(values, self).any?

    value
  end
end
