# frozen_string_literal: true

module Maintenance
  class BackfillMissingEntrepriseDataTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      Etablissement
        .where(created_at: 6.months.ago..)
        .where.not(siret: nil)
        .where(entreprise_siren: nil)
        .left_joins(:dossier, :champ)
        .where("dossiers.id IS NOT NULL OR champs.id IS NOT NULL")
        .distinct
    end

    def process(etablissement)
      procedure_id = find_procedure_id(etablissement)
      return if procedure_id.nil?

      # Add delay
      wait_time = rand(0..max_wait)
      APIEntreprise::EntrepriseJob.set(wait: wait_time.seconds).perform_later(etablissement.id, procedure_id)
    rescue StandardError => e
      # Log l'erreur mais continue avec les autres établissements
      Rails.logger.error("BackfillMissingEntrepriseDataTask: Error processing etablissement #{etablissement.id}: #{e.message}")
      Sentry.capture_exception(e, extra: { etablissement_id: etablissement.id, siret: etablissement.siret })
    end

    private

    def max_wait
      # spread the jobs over 10 seconds * number of etablissements
      count * 10
    end

    def find_procedure_id(etablissement)
      d = dossier(etablissement)
      d&.procedure&.id
    end

    def dossier(etablissement)
      etablissement.dossier || etablissement.champ&.dossier
    end
  end
end
