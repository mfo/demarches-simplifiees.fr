# frozen_string_literal: true

module Maintenance
  class T20260504BackfillCanonicalKeysInDepartementChampsTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    def collection
      Champs::DepartementChamp.all
    end

    def process(champ)
      current = champ.value_json || {}

      additions = {
        'department_code' => champ.code,
        'region_code' => current['code_region'],
      }.compact

      result = current.merge(additions)
      champ.update_column(:value_json, result) if result != current
    end
  end
end
