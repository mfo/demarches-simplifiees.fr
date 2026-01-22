# frozen_string_literal: true

module Maintenance
  class T20260120fixRestoredDossiersThatRemainExpiredTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de prolonger la durée de conservation
    # de dossiers terminés qui historiquement ont : (i) été supprimés manuellement par
    # l'administration, puis (ii) expirés automatiquement, et enfin (iii) restaurés
    # par l'administration avant leur suppression définitive via l'action en masse
    # "restaurer" simplement (cad sans étendre la durée de conservation),
    # correspondant à un bug d'une action permise, corrigée dans la PR#12537.
    # Les dossiers se retrouvent ainsi dans un état incohérent à savoir : une date
    # dans hidden_by_expired_at, et un hidden_by_reason à nil.
    # Il est ainsi proposé ici d'ajouter une durée de conservation supplémentaire
    # aux dossiers concernés (et de recalculer leur date d'expiration), de sorte
    # à ce qu'il expire dans 1 mois à compter du lancement de la MT.
    # NB: l'action "restaurer" simplement ne pouvait pas fonctionner pour les dossiers
    # en_construction (car non supprimable manuellement par l'administration). On
    # peut donc se passer du scope "state_termine" dans la collection.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Dossier.hidden_by_expired.where(hidden_by_reason: nil)
    end

    def process(dossier)
      expired_at = dossier.expired_at
      now = Time.zone.now

      nb_months_since_expiration = (now.to_date.year * 12 + now.to_date.month) - (expired_at.to_date.year * 12 + expired_at.to_date.month)

      conservation_extension = (nb_months_since_expiration + 1).months

      dossier.update!(
        conservation_extension: dossier.conservation_extension + conservation_extension,
        termine_close_to_expiration_notice_sent_at: nil,
        hidden_by_expired_at: nil
      )
      dossier.update_expired_at
    end

    def count
      collection.count
    end
  end
end
