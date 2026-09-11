# frozen_string_literal: true

class Cron::UpdateStatsJob < Cron::CronJob
  self.schedule_expression = "every 1 hour"
  recovers_by :next_run

  def perform(*args)
    Stat.update_stats
  end
end
