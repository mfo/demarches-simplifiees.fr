# frozen_string_literal: true

module Maintenance
  class T20260128desarchiveNotTermineDossiersTask < MaintenanceTasks::Task
    # Documentation: cette tâche désarchive les dossiers non terminés
    # dont les ids sont passés en paramètre (séparés par des virgules)

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    attribute :dossier_ids, :string
    validates :dossier_ids, presence: true

    def collection
      Dossier
        .where(id: dossier_ids.split(',').map(&:strip).map(&:to_i))
        .where(archived: true)
        .where(state: Dossier::EN_CONSTRUCTION_OU_INSTRUCTION)
    end

    def process(dossier)
      dossier.update_columns(archived: false, archived_at: nil, archived_by: nil)
    end
  end
end
