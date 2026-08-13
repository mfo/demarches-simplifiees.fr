# frozen_string_literal: true

class TypesDeChamp::PreRempliTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def self.category = REFERENTIEL_EXTERNE
  def self.editable_option_keys = [:drop_down_options, :pre_rempli_hidden]

  def cannot_be_mandatory? = true
end
