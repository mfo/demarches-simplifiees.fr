# frozen_string_literal: true

class TypesDeChamp::IbanTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def self.category = PAIEMENT_IDENTIFICATION

  def prefillable? = true

  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def typed_champ_value_for_api(champ, version: 2)
    typed_champ_value(champ).gsub(/\s+/, '')
  end
end
