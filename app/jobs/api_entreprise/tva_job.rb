# frozen_string_literal: true

class APIEntreprise::TvaJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    with_adapter(APIEntreprise::TvaAdapter.new(etablissement.siret, procedure_id)) do |params|
      etablissement.update!(params)
    end
  end
end
