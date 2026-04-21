# frozen_string_literal: true

module AvisCreationConcern
  extend ActiveSupport::Concern

  def handle_create_avis(dossier:, user:, avis:, success_path:, error_template:, avis_source: nil)
    emails = Array(avis.emails).map(&:strip).map(&:downcase).compact_blank

    if emails.empty?
      email_label = User.human_attribute_name(:email)
      flash.now[:alert] = format(I18n.t('errors.format'), attribute: email_label, message: I18n.t('errors.messages.blank'))
      render error_template, status: :unprocessable_content
      return
    end

    result = CreateAvisService.call(
      instructeur_or_expert: user,
      dossier:,
      batch: false,
      avis:,
      avis_source:
    )

    if result.sent_emails.any?
      if result.sent_emails.count < 5
        flash[:notice] = "Une demande d’avis a été envoyée à #{result.sent_emails.join(', ')}"
      else
        flash[:notice] = "Une demande d’avis a été envoyée à #{result.sent_emails.count} destinataires"
      end
    end

    if result.failed_emails.any?
      flash.now[:alert] = result.failed_emails.flat_map do |failed|
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
