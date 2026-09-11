# frozen_string_literal: true

class Cron::WeeklyOverviewJob < Cron::CronJob
  self.schedule_expression = "every monday at 04:05"
  # Arbitrage: the digest of a lost monday is never re-sent, but 3 of the 4 figures of
  # ProcedureOverview are snapshots of the current backlog, which show up intact the
  # week after; only @created_dossiers_count is windowed.
  recovers_by :next_run

  def perform
    # Feature flipped to avoid mails in staging due to unprocessed dossier
    return unless Rails.application.config.ds_weekly_overview

    Instructeur
      .joins(:instructeurs_procedures)
      .where(instructeurs_procedures: { weekly_email_summary: true })
      .distinct
      .find_each do |instructeur|
        # mailer won't send anything if overview is empty
        InstructeurMailer.last_week_overview(instructeur)&.deliver_later(wait: rand(0..3.hours))
      end
  end
end
