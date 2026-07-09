# frozen_string_literal: true

class TypesDeChamp::PrefillRegionTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def all_possible_values
    regions.map { |region| "#{region[:code]} (#{region[:name]})" }
  end

  # Mirrors Champs::RegionChamp#value=: a 2-character value is treated as a
  # region code, anything else as a region name.
  def to_assignable_attributes(champ, value)
    return nil if !value.is_a?(String)

    resolvable = if value.size == 2
      APIGeoService.region_name(value).present?
    else
      APIGeoService.region_code(value).present?
    end
    return nil if !resolvable

    { value: }
  end

  private

  def regions
    @regions ||= APIGeoService.regions.sort_by { |region| region[:code] }
  end
end
