# frozen_string_literal: true

class TypesDeChamp::PrefillPaysTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def all_possible_values
    countries.map { |country| "#{country[:code]} (#{country[:name]})" }
  end

  private

  # Mirrors Champs::PaysChamp#value=, which nils out unrecognized codes or
  # names: a value we cannot resolve to a country would be silently erased.
  def screened_value(champ, value)
    return nil if !value.is_a?(String)

    value if resolvable?(value)
  end

  def resolvable?(value)
    if value.size == 2
      APIGeoService.country_name(value, locale: 'FR').present?
    else
      APIGeoService.country_code(value).present?
    end
  end

  def countries
    @countries ||= APIGeoService.countries.sort_by { |country| country[:code] }
  end
end
