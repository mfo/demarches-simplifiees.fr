# frozen_string_literal: true

class APIEntreprise::AssociationJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    with_adapter(APIEntreprise::RNAAdapter.new(etablissement.siret, procedure_id)) do |params|
      # Adresse is already populated by EtablissementJob as an inlined adresse, not a hash.
      etablissement.update!(params.except("adresse"))
    end
  end
end
