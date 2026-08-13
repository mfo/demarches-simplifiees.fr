# frozen_string_literal: true

class TypesDeChamp::AnnuaireEducationTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def self.category = REFERENTIEL_EXTERNE

  def prefillable? = false

  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end
end
