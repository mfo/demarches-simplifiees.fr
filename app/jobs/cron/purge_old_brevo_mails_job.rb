# frozen_string_literal: true

class Cron::PurgeOldBrevoMailsJob < Cron::CronJob
  self.schedule_expression = "every day at 00:15"

  # Deletes one specific day (today - 31 days): a lost run is never caught up, and a
  # retry crossing midnight would delete the following day instead of the lost one.
  recovers_by :never

  def perform
    brevo = Brevo::API.new
    day_to_delete = (Time.zone.today - 31.days).strftime("%Y-%m-%d")
    brevo.delete_events(day_to_delete)
  end
end
