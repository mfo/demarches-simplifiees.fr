# frozen_string_literal: true

class TypesDeChamp::PrefillCiviliteTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  CIVILITES = [Individual::GENDER_MALE, Individual::GENDER_FEMALE].freeze

  private

  def screened_value(champ, value)
    value if value.in?(CIVILITES)
  end
end
