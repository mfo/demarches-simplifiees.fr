# frozen_string_literal: true

class Champs::IntegerNumberChamp < ChampData
  validates_with NumberFormatValidator, if: :should_validate_in_current_context?
  validates_with NumberLimitValidator, if: :should_validate_in_current_context?
  normalizes :value, with: -> { NumberFormatValidator.normalize(it) }
end
