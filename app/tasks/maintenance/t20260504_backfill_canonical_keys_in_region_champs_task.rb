# frozen_string_literal: true

module Maintenance
  class T20260504BackfillCanonicalKeysInRegionChampsTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    def collection
      Champs::RegionChamp.all
    end

    def process(champ)
      current = champ.value_json || {}

      additions = { 'region_code' => champ.code }.compact

      result = current.merge(additions)
      champ.update_column(:value_json, result) if result != current
    end
  end
end
