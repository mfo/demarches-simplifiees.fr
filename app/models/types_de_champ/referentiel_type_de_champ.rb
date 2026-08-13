# frozen_string_literal: true

class TypesDeChamp::ReferentielTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def self.category = REFERENTIEL_EXTERNE
  def self.editable_option_keys = [:referentiel_mapping]
end
