# frozen_string_literal: true

module Maintenance
  class T20260521BackfillGeoAreaUuidTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      GeoArea.joins(:champ).where(champs: { stream: Champ::MAIN_STREAM })
    end

    def process(geo_area)
      uuid = geo_area.uuid || SecureRandom.uuid
      geo_area.update_column(:uuid, uuid) if geo_area.uuid.nil?
      champ = geo_area.champ
      GeoArea.joins(:champ)
        .where(geometry: geo_area.geometry, champs: { dossier_id: champ.dossier_id, stable_id: champ.stable_id, row_id: champ.row_id })
        .where.not(champs: { stream: Champ::MAIN_STREAM })
        .update_all(uuid:)
    end
  end
end
