# frozen_string_literal: true

module Maintenance
  class T20260805BackfillChampsValueUpdatedAtFromCheckpointTask < MaintenanceTasks::Task
    # `champs.value_updated_at` date les modifications utilisateur ; elle n'est
    # renseignée que depuis son introduction. Pour les champs déjà fusionnés
    # depuis un buffer stream, l'instant exact de la fusion est encodé dans
    # `checkpoint` (« history:<time> », le même `now` que l'`updated_at` posé
    # par la fusion) : on le recopie pour que ces champs ne retombent plus sur
    # `updated_at`, faussé par la mécanique interne (purge de pièces jointes,
    # récupérations de données externes…).
    #
    # Les champs sans checkpoint (jamais modifiés après dépôt, ou fusionnés
    # avant l'introduction de la colonne checkpoint le 2026-06-02) ne sont pas
    # traités et conservent le repli sur `updated_at`.
    #
    # La table champs est volumineuse et les champs avec checkpoint y sont
    # rares : filtrer dans `collection` ferait balayer des millions de lignes
    # sans correspondance à chaque requête de curseur d'in_batches (statement
    # timeout). On parcourt donc toute la table par plages de clé primaire et
    # on filtre dans l'UPDATE de chaque lot, calculé entièrement en SQL.

    include RunnableOnDeployConcern

    run_on_first_deploy

    BATCH_SIZE = 10_000

    def collection
      ChampData.in_batches(of: BATCH_SIZE)
    end

    def process(batch)
      batch
        .where(stream: Dossier::MAIN_STREAM, value_updated_at: nil)
        .where.not(checkpoint: nil)
        .update_all([
          "value_updated_at = substring(checkpoint from ?)::timestamptz AT TIME ZONE 'UTC'",
          Dossier::HISTORY_STREAM.length + 1,
        ])
    end

    def count
      # la table champs est volumineuse, le COUNT déclenche des PG statement timeout
    end
  end
end
