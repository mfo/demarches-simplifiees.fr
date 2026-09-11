# frozen_string_literal: true

class Cron::PurgeStaleBatchOperationJob < Cron::CronJob
  self.schedule_expression = "every 5 minutes"
  recovers_by :next_run

  def perform
    BatchOperation.stale.destroy_all
    BatchOperation.stuck.destroy_all
  end
end
