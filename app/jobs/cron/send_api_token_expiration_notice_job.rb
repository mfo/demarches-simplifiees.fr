# frozen_string_literal: true

class Cron::SendAPITokenExpirationNoticeJob < Cron::CronJob
  self.schedule_expression = "every day at 23:45"

  # `APIToken.expiring_within` is lower-bounded by `Date.today`, so a token expiring
  # before the next run drops out of the scope for good and its last-chance notice is
  # never sent. Its sibling SendAPIEntrepriseTokenExpirationNoticeJob has no such lower
  # bound (`expired_or_expires_soon?`) and does catch up, hence no budget there.
  # 5 retries span 7 minutes, and this 23:45 job only has 15 before midnight closes
  # its scope -- anything beyond that would retry for nothing.
  use_sidekiq_retry(max_retry: 5, report_after_attempts: 5)

  def perform
    windows = [
      1.day,
      1.week,
      1.month,
    ]

    windows.each do |window|
      APIToken
        .with_expiration_notice_to_send_for(window)
        .find_each do |token|
        APITokenMailer.expiration(token).deliver_later
        token.expiration_notices_sent_at << Time.zone.today
        token.save!
      end
    end
  end
end
