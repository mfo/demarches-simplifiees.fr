# frozen_string_literal: true

class Cron::StalledDeclarativeProceduresJob < Cron::CronJob
  self.schedule_expression = "every 10 minutes"

  def perform
    Dossier.state_en_construction
      .where(declarative_triggered_at: nil)
      .joins(:procedure).merge(Procedure.declarative.publiees_ou_closes)
      .find_each { ProcessStalledDeclarativeDossierJob.perform_later(it) }
  end
end
