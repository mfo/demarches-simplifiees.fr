# frozen_string_literal: true

class Champs::DecimalNumberChamp < ChampData
  validates_with NumberFormatValidator, if: :should_validate_in_current_context?
  validates_with NumberLimitValidator, if: :should_validate_in_current_context?
  normalizes :value, with: -> { NumberFormatValidator.normalize(it, decimal: true) }

  # TODO expose raw typed value of champs
  def condition_value = type_de_champ.champ_value_for_api(self, version: 1)
end
