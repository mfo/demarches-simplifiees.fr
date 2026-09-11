# frozen_string_literal: true

class Cron::NotifyDraftNotSubmittedJob < Cron::CronJob
  self.schedule_expression = "from monday through friday at 7 am"

  # `Dossier.brouillon_near_procedure_closing_date` matches on a date equality
  # (`auto_archive_on - INTERVAL '2 days' = today`), not on a range: tomorrow's run
  # targets a different set of dossiers, so the reminder of a lost run is never sent.
  # The short budget matters twice here: `notify_draft_not_submitted` has no idempotence
  # guard, so an attempt that dies midway through `find_each` re-mails every usager it
  # already notified.
  recovers_by :never

  def perform(*args)
    Dossier.notify_draft_not_submitted
  end
end
