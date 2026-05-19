# frozen_string_literal: true

class APIEntreprise::BilansBdfJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    with_adapter(APIEntreprise::BilansBdfAdapter.new(etablissement.siret, procedure_id)) do |params|
      etablissement.update!(params)
    end
  end
end
