# frozen_string_literal: true

class Cron::PurgeStaleTransfersJob < Cron::CronJob
  self.schedule_expression = "every day at 00:00"
  recovers_by :next_run

  def perform
    DossierTransfer.destroy_stale
  end
end
