# frozen_string_literal: true

class TypesDeChamp::DossierLinkTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def self.category = STRUCTURE
  def self.editable_option_keys = [:procedures_limit, :dossier_link_procedure_ids]
end
