# frozen_string_literal: true

class TypesDeChamp::PrefillRegionTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def all_possible_values
    regions.map { |region| "#{region[:code]} (#{region[:name]})" }
  end

  private

  # Mirrors Champs::RegionChamp#value=: a 2-character value is treated as a
  # region code, anything else as a region name.
  def screened_value(champ, value)
    return nil if !value.is_a?(String)

    value if resolvable?(value)
  end

  def resolvable?(value)
    if value.size == 2
      APIGeoService.region_name(value).present?
    else
      APIGeoService.region_code(value).present?
    end
  end

  def regions
    @regions ||= APIGeoService.regions.sort_by { |region| region[:code] }
  end
end
