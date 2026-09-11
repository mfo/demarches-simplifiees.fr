# frozen_string_literal: true

class Cron::PurgeOldBrevoMailsJob < Cron::CronJob
  self.schedule_expression = "every day at 00:15"

  # Deletes one specific day (today - 31 days): a lost run is never caught up, and a
  # retry crossing midnight would delete the following day instead of the lost one.
  # 5 retries span 7 minutes: enough to outlast a restart or a Brevo hiccup, and
  # Sentry only hears about it if the failure is still there at the end.
  use_sidekiq_retry(max_retry: 5, report_after_attempts: 5)

  def perform
    brevo = Brevo::API.new
    day_to_delete = (Time.zone.today - 31.days).strftime("%Y-%m-%d")
    brevo.delete_events(day_to_delete)
  end
end
