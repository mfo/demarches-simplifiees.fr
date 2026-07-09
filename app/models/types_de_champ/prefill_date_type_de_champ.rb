# frozen_string_literal: true

class TypesDeChamp::PrefillDateTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def to_assignable_attributes(champ, value)
    return nil if !value.is_a?(String)

    iso_date = DateDetectionUtils.convert_to_iso8601_date(value)
    return nil if iso_date.nil?
    return nil if DateLimitValidator.violations(iso_date, self).any?

    { value: iso_date }
  end
end
