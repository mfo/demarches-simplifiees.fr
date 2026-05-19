# frozen_string_literal: true

class APIEntreprise::EntrepriseJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    with_adapter(APIEntreprise::EntrepriseAdapter.new(etablissement.siret, procedure_id)) do |params|
      etablissement.update!(params)
      etablissement.update_champ_value_json!
    end
  end
end
