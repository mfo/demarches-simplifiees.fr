# frozen_string_literal: true

class TypesDeChamp::PrefillDatetimeTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def to_assignable_attributes(champ, value)
    return nil if !value.is_a?(String)

    iso_datetime = DateDetectionUtils.convert_to_iso8601_datetime(value)
    return nil if iso_datetime.nil?
    return nil if DateLimitValidator.violations(iso_datetime, self).any?

    { value: iso_datetime }
  end
end
