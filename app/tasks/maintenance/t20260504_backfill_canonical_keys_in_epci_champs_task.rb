# frozen_string_literal: true

module Maintenance
  class T20260504BackfillCanonicalKeysInEpciChampsTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    def collection
      Champs::EpciChamp.all
    end

    def process(champ)
      current = champ.value_json || {}

      additions = {
        'department_code' => current['code_departement'],
        'region_code' => current['code_region'],
      }.compact

      result = current.merge(additions)
      champ.update_column(:value_json, result) if result != current
    end
  end
end
