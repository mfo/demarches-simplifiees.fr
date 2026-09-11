# frozen_string_literal: true

class Cron::AdministrateurActivateBeforeExpirationJob < Cron::CronJob
  self.schedule_expression = "every day at 08:00"

  # `created_at: 3.days.ago.all_day` is a one-day window: tomorrow's run targets the
  # administrateurs created a day later, so a lost run is never caught up. Kept to 7
  # minutes rather than the full budget: `remind_invitation!` rotates the reset
  # password token, so every duplicate mail kills the link sent by the previous one.
  use_sidekiq_retry(max_retry: 5, report_after_attempts: 5)

  def perform(*args)
    Administrateur
      .includes(:user)
      .inactive
      .where(created_at: 3.days.ago.all_day)
      .find_each { |a| a.user.remind_invitation! }
  end
end
