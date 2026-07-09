# frozen_string_literal: true

class TypesDeChamp::PrefillDepartementTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def all_possible_values
    departements.map { |departement| "#{departement[:code]} (#{departement[:name]})" }
  end

  # Mirrors Champs::DepartementChamp#value=: a 2 or 3 characters value is
  # treated as a departement code, anything else as a departement name.
  def to_assignable_attributes(champ, value)
    return nil if !value.is_a?(String)

    resolvable = if [2, 3].include?(value.size)
      APIGeoService.departement_name(value).present?
    else
      APIGeoService.departement_code(value).present?
    end
    return nil if !resolvable

    { value: }
  end

  private

  def departements
    @departements ||= APIGeoService.departements.sort_by { |departement| departement[:code] }
  end
end
