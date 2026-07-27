# frozen_string_literal: true

module Maintenance
  class T20260722updateProcedureEstimatedDossiersCountTask < MaintenanceTasks::Task
    # Documentation: cette tâche fait suite à la PR#XXXXX qui vient modifier la
    # formule de calcul de :estimated_dossiers_count, afin de comptabiliser
    # l'ensemble des dossiers qui ont été déposés à l'administration.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    no_collection

    def process
      Procedure.not_brouillon.find_each do |p|
        p.update_columns(
          estimated_dossiers_count: dossiers_counts.fetch(p.id, 0),
          dossiers_count_computed_at: Time.zone.now
        )
      end
    end

    private

    def dossiers_counts
      @dossiers_counts ||= begin
        counts = Hash.new(0)

        Dossier.submitted_to_administration
          .joins(:procedure)
          .group('procedure.id')
          .count
          .each do |procedure_id, count|
            counts[procedure_id] += count
          end

        DeletedDossier.submitted_to_administration
          .group(:procedure_id)
          .count
          .each do |procedure_id, count|
            counts[procedure_id] += count
          end

        counts
      end
    end
  end
end
