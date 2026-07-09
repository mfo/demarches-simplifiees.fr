# frozen_string_literal: true

class TypesDeChamp::PrefillCiviliteTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  CIVILITES = [Individual::GENDER_MALE, Individual::GENDER_FEMALE].freeze

  def to_assignable_attributes(champ, value)
    return nil if !value.in?(CIVILITES)

    { value: }
  end
end
