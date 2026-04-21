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
      dossier: avis.dossier,
      claimant:,
      batch: false,
      avis:,
      avis_source:
    )

    if sent_emails.any?
      if sent_emails.count < 5
        flash[:notice] = "Une demande d’avis a été envoyée à #{sent_emails.join(', ')}"
      else
        flash[:notice] = "Une demande d’avis a été envoyée à #{sent_emails.count} destinataires"
      end
    end

    if failed_emails.any?
      flash.now[:alert] = failed_emails.flat_map do |failed|
        if failed[:email].blank?
          failed[:messages]
        else
          "#{failed[:email]} : #{failed[:messages].join(', ')}"
        end
      end.join(' | ')

      render error_template, status: :unprocessable_content
    else
      redirect_to success_path
    end
  end
end
