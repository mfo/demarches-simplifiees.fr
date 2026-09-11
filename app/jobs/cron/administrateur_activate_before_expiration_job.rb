# frozen_string_literal: true

class Cron::AdministrateurActivateBeforeExpirationJob < Cron::CronJob
  self.schedule_expression = "every day at 08:00"

  # `created_at: 3.days.ago.all_day` is a one-day window: tomorrow's run targets the
  # administrateurs created a day later, so a lost run is never caught up. The short
  # budget matters twice here: `remind_invitation!` rotates the reset password token, so
  # every duplicate mail kills the link sent by the previous one.
  recovers_by :never

  def perform(*args)
    Administrateur
      .includes(:user)
      .inactive
      .where(created_at: 3.days.ago.all_day)
      .find_each { |a| a.user.remind_invitation! }
  end
end
