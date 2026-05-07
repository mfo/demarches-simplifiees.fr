# frozen_string_literal: true

class APIEntreprise::EffectifsAnnuelsJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id, year = default_year)
    find_etablissement(etablissement_id)
    with_adapter(APIEntreprise::EffectifsAnnuelsAdapter.new(etablissement.siret, procedure_id, year)) do |params|
      etablissement.update!(params)
    end
  end

  private

  def default_year
    Date.current.year - 1
  end
end
