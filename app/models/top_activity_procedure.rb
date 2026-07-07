# frozen_string_literal: true

class TopActivityProcedure
  extend ActiveModel::Naming
  extend ActiveModel::Translation

  attr_accessor :id,
                :libelle,
                :published_at,
                :dossiers_7_jours,
                :dossiers_total

  def persisted?
    false
  end

  def self.all
    procedures_with_activity_sql = Procedure
      .publiees
      .where(published_at: 1.month.ago..)
      .select(
        <<~SQL.squish
          procedures.id,
          procedures.libelle,
          procedures.published_at,
          procedures.estimated_dossiers_count AS dossiers_total,
          COUNT(dossiers.id) AS dossiers_7_jours
        SQL
      )
      .joins(:dossiers)
      .where(dossiers: { depose_at: 7.days.ago.. })
      .group("procedures.id")
      .order(dossiers_7_jours: :desc)
      .limit(20)
      .to_sql

    ActiveRecord::Base.connection.execute(procedures_with_activity_sql).map do |procedure|
      p = TopActivityProcedure.new
      p.id = procedure["id"]
      p.libelle = procedure["libelle"]
      p.published_at = procedure["published_at"]
      p.dossiers_7_jours = procedure["dossiers_7_jours"]
      p.dossiers_total = procedure["dossiers_total"]
      p
    end
  end
end
