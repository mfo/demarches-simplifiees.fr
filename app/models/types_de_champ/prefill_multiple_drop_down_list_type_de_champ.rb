# frozen_string_literal: true

class TypesDeChamp::PrefillMultipleDropDownListTypeDeChamp < TypesDeChamp::PrefillDropDownListTypeDeChamp
  def example_value
    return nil if all_possible_values.empty?
    return all_possible_values.first if all_possible_values.one?

    [all_possible_values.first, all_possible_values.second]
  end

  def to_assignable_attributes(champ, value)
    return nil if !acceptable_prefill_value?(value)

    values = extract_values(value)
    return nil if DropDownOptionsValidator.violations(values, self).any?

    { value: }
  end

  private

  # Mirrors the parsing done by Champs::MultipleDropDownListChamp#value=.
  def extract_values(value)
    values = if value.is_a?(Array)
      value
    elsif value.is_a?(String) && value.starts_with?('[')
      JSON.parse(value) rescue [value]
    else
      [value]
    end
    values.uniq.compact_blank
  end
end
