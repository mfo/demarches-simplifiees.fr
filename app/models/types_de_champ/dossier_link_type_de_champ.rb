# frozen_string_literal: true

class TypesDeChamp::DossierLinkTypeDeChamp < TypeDeChamp
  def self.category = STRUCTURE
  def self.editable_option_keys = [:procedures_limit, :dossier_link_procedure_ids]

  def prefillable? = true
  def customizable? = true
end
