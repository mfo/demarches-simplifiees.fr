# frozen_string_literal: true

class TypesDeChamp::PrefillDateTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  private

  def screened_value(champ, value)
    return nil if !value.is_a?(String)

    iso_value = if datetime?
      DateDetectionUtils.convert_to_iso8601_datetime(value)
    else
      DateDetectionUtils.convert_to_iso8601_date(value)
    end
    return nil if iso_value.nil?
    return nil if DateLimitValidator.violations(iso_value, self).any?

    iso_value
  end
end
