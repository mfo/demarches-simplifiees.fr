# frozen_string_literal: true

class Cron::NotifyDraftNotSubmittedJob < Cron::CronJob
  self.schedule_expression = "from monday through friday at 7 am"

  # `Dossier.brouillon_near_procedure_closing_date` matches on a date equality
  # (`auto_archive_on - INTERVAL '2 days' = today`), not on a range: tomorrow's run
  # targets a different set of dossiers, so the reminder of a lost run is never sent.
  # Kept to 7 minutes rather than the full budget: `notify_draft_not_submitted` has no
  # idempotence guard, so an attempt that dies midway through `find_each` re-mails
  # every usager it already notified.
  use_sidekiq_retry(max_retry: 5, report_after_attempts: 5)

  def perform(*args)
    Dossier.notify_draft_not_submitted
  end
end
