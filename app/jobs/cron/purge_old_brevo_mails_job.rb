# frozen_string_literal: true

class Cron::PurgeOldBrevoMailsJob < Cron::CronJob
  self.schedule_expression = "every day at 00:15"

  # Deletes one specific day (today - 31 days): a lost run is never caught up, and a
  # retry crossing midnight would delete the following day instead of the lost one.
  # The window is the day itself, so 10 retries (about four hours, done by 04:30)
  # outlast a real Brevo outage while staying well clear of midnight; deleting the
  # same day twice is harmless. Sentry only hears about it if the failure is still
  # there at the end.
  use_sidekiq_retry(max_retry: 10, report_after_attempts: 10)

  def perform
    brevo = Brevo::API.new
    day_to_delete = (Time.zone.today - 31.days).strftime("%Y-%m-%d")
    brevo.delete_events(day_to_delete)
  end
end
