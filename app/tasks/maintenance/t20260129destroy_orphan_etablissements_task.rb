# frozen_string_literal: true

module Maintenance
  # Supprime les établissements orphelins créés par le bug dans SiretChamp#after_reset_external_data
  # Ces établissements n'ont ni dossier_id ni champ associé et ne sont plus accessibles.
  class T20260129destroyOrphanEtablissementsTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      with_statement_timeout("5min") do
        Etablissement.where(dossier_id: nil).where.missing(:champ)
      end
    end

    def process(etablissement)
      etablissement.destroy!
    end

    def count
      collection.count
    end
  end
end
