# frozen_string_literal: true

module Maintenance
  class T20260504BackfillCanonicalKeysInCommuneChampsTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    def collection
      Champs::CommuneChamp.all
    end

    def process(champ)
      current = champ.value_json || {}

      additions = {
        'postal_code' => current['code_postal'],
        'department_code' => current['code_departement'],
        'region_code' => current['code_region'],
        'city_name' => champ.value,
        'city_code' => champ.external_id,
      }.compact

      result = current.merge(additions)
      champ.update_column(:value_json, result) if result != current
    end
  end
end
