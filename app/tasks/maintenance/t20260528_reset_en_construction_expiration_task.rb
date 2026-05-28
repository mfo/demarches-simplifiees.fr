# frozen_string_literal: true

module Maintenance
  class T20260528ResetEnConstructionExpirationTask < MaintenanceTasks::Task
    # Documentation: les dossiers en_construction n'expirent plus (#13178). Les
    # notifications dossier_expirant déjà créées sur ces dossiers continueraient
    # de s'afficher (l'affichage ne revérifie pas close_to_expiration?). Cette
    # tâche les détruit. La colonne en_construction_close_to_expiration_notice_sent_at
    # et expired_at résiduels ne sont plus lus pour en_construction : on les ignore
    # (la colonne sera supprimée dans une MEP ultérieure).

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      DossierNotification
        .where(notification_type: :dossier_expirant)
        .where(dossier_id: Dossier.state_en_construction.select(:id))
    end

    def process(notification)
      notification.destroy
    end

    def count
      with_statement_timeout("5min") do
        collection.count
      end
    end
  end
end
