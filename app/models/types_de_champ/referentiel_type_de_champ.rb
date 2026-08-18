# frozen_string_literal: true

class TypesDeChamp::ReferentielTypeDeChamp < TypeDeChamp
  def self.category = REFERENTIEL_EXTERNE
  def self.editable_option_keys = [:referentiel_mapping]

  def prefillable? = referentiel_in_exact_match?
end
