# frozen_string_literal: true

module AvisCreationConcern
  extend ActiveSupport::Concern

  def handle_create_avis(claimant:, avis:, success_path:, error_template:, avis_source: nil)
    emails = Array(avis.emails).map(&:strip).map(&:downcase).compact_blank

    if emails.empty?
      email_label = User.human_attribute_name(:email)
      flash.now[:alert] = format(I18n.t('errors.format'), attribute: email_label, message: I18n.t('errors.messages.blank'))
      render error_template, status: :unprocessable_content
      return
    end

    sent_emails, failed_emails = CreateAvisService.call(
      claimant:,
      batch: false,
      avis:,
      avis_source:
    )

    flash[:notice] = sent_emails_notice(sent_emails) if sent_emails.any?

    if failed_emails.any?
      flash.now[:alert] = failed_emails_alert(failed_emails)
      render error_template, status: :unprocessable_content
    else
      redirect_to success_path
    end
  end

  private

  def sent_emails_notice(sent_emails)
    if sent_emails.count < 5
      t('avis_creation_concern.avis_sent.with_emails', emails: sent_emails.join(', '))
    else
      t('avis_creation_concern.avis_sent.with_count', count: sent_emails.count)
    end
  end

  def failed_emails_alert(failed_emails)
    failed_emails.flat_map do |failed|
      if failed[:email].blank?
        failed[:messages]
      else
        "#{failed[:email]} : #{failed[:messages].join(', ')}"
      end
    end.join(' | ')
  end
end
