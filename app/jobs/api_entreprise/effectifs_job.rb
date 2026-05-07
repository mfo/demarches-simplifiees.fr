# frozen_string_literal: true

class APIEntreprise::EffectifsJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    year, month = get_current_valid_month_for_effectif
    with_adapter(APIEntreprise::EffectifsAdapter.new(etablissement.siret, procedure_id, year, month)) do |params|
      etablissement.update!(params)
    end
  end

  private

  def get_current_valid_month_for_effectif
    today = Date.today
    date_update = Date.new(today.year, today.month, 15)

    if today >= date_update
      [today.strftime("%Y"), today.strftime("%m")]
    else
      date = today - 1.month
      [date.strftime("%Y"), date.strftime("%m")]
    end
  end
end
