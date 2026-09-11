# frozen_string_literal: true

class Cron::APIEntrepriseHealthCheckJob < Cron::CronJob
  self.schedule_expression = "every 2 minutes"
  recovers_by :next_run

  def perform
    APIEntreprise::HealthChecker.refresh_all!
  end
end
