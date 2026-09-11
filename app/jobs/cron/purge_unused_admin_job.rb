# frozen_string_literal: true

class Cron::PurgeUnusedAdminJob < Cron::CronJob
  self.schedule_expression = "every monday at 5:15"
  recovers_by :next_run

  def perform(*args)
    Administrateur.unused.destroy_all
  end
end
