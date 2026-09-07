# frozen_string_literal: true

class CarteController < ApplicationController
  def show
    @map_filter = MapFilter.new(map_filter_params)
    @map_filter.validate

    # Reset to default params in case of invalid params injection
    @map_filter.kind = MapFilter.new.kind if @map_filter.errors.key?(:kind)
    @map_filter.year = MapFilter.new.year if @map_filter.errors.key?(:year)
    @map_filter.errors.clear

    @map_filter.stats = stats
  end

  private

  def map_filter_params
    return {} if !params.key?(:map_filter)

    # A scalar where a hash is expected (`?map_filter=x`) is a bad request,
    # not a NoMethodError on String.
    params.expect(map_filter: [:kind, :year])
  end

  def stats
    departements_sql = "select departement, count(procedures.id) as nb_demarches, sum(procedures.estimated_dossiers_count) as nb_dossiers from services inner join procedures on services.id = procedures.service_id where procedures.hidden_at is null and procedures.aasm_state in ('publiee', 'close', 'depubliee')"
    if @map_filter.year.present?
      departements_sql += ActiveRecord::Base.sanitize_sql([" and procedures.published_at between ? and ?", "#{@map_filter.year}-01-01", "#{@map_filter.year}-12-31"])
    end
    departements_sql += " group by services.departement"
    departements = ActiveRecord::Base.connection.execute(departements_sql)
    departements.to_a.reduce(Hash.new({ nb_demarches: 0, nb_dossiers: 0 })) do |h, v|
      h.merge(
        v["departement"] => {
          'nb_demarches': v["nb_demarches"].presence || 0,
          'nb_dossiers': v['nb_dossiers'].presence || 0,
        }
      )
    end
  end
end
