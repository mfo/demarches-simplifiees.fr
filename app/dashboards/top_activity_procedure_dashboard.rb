# frozen_string_literal: true

require "administrate/base_dashboard"

class TopActivityProcedureDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    libelle: Field::String,
    published_at: Field::DateTime,
    dossiers_7_jours: Field::Number,
    dossiers_total: Field::Number,
  }.freeze

  COLLECTION_ATTRIBUTES = [
    :id,
    :libelle,
    :published_at,
    :dossiers_7_jours,
    :dossiers_total,
  ].freeze

  COLLECTION_FILTERS = {}.freeze
  SHOW_PAGE_ATTRIBUTES = {}
end
