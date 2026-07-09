# frozen_string_literal: true

class TypesDeChamp::PrefillPaysTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def all_possible_values
    countries.map { |country| "#{country[:code]} (#{country[:name]})" }
  end

  # Mirrors Champs::PaysChamp#value=, which nils out unrecognized codes or
  # names: a value we cannot resolve to a country would be silently erased.
  def to_assignable_attributes(champ, value)
    return nil if !value.is_a?(String)

    resolvable = if value.size == 2
      APIGeoService.country_name(value, locale: 'FR').present?
    else
      APIGeoService.country_code(value).present?
    end
    return nil if !resolvable

    { value: }
  end

  private

  def countries
    @countries ||= APIGeoService.countries.sort_by { |country| country[:code] }
  end
end
