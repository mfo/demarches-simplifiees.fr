# frozen_string_literal: true

module Maintenance
  class T20260528ResetEnConstructionExpirationTask < MaintenanceTasks::Task
    # Documentation: les dossiers en_construction n'expirent plus (#13178). Les
    # notifications dossier_expirant déjà créées sur ces dossiers continueraient
    # de s'afficher (l'affichage ne revérifie pas close_to_expiration?). Cette
    # tâche les détruit. La colonne en_construction_close_to_expiration_notice_sent_at
    # n'est plus lue pour en_construction : on l'ignore (la colonne sera
    # supprimée dans une MEP ultérieure).

    include RunnableOnDeployConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      DossierNotification
        .where(notification_type: :dossier_expirant)
        .where(dossier_id: Dossier.state_en_construction.select(:id))
        .in_batches
    end

    def process(batch)
      batch.delete_all
    end
  end
end
