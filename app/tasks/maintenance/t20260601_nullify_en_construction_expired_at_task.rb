# frozen_string_literal: true

module Maintenance
  class T20260601NullifyEnConstructionExpiredAtTask < MaintenanceTasks::Task
    # Documentation: les dossiers en_construction n'expirent plus (#13178).
    # Les nouvelles transitions vers en_construction remettent expired_at à nil
    # via after_passer_en_construction. Cette tâche nettoie la valeur résiduelle
    # sur le stock historique pour cohérence (notamment API GraphQL date_expiration).

    include RunnableOnDeployConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Dossier.state_en_construction.where.not(expired_at: nil).in_batches
    end

    def process(batch)
      batch.update_all(expired_at: nil)
    end
  end
end
