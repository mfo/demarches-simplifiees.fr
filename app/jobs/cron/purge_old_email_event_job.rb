# frozen_string_literal: true

class Cron::PurgeOldEmailEventJob < Cron::CronJob
  self.schedule_expression = "every week at 3:00"
  recovers_by :next_run

  def perform
    EmailEvent.outdated.in_batches.destroy_all
  end
end
