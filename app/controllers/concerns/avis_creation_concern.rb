# frozen_string_literal: true

module AvisCreationConcern
  extend ActiveSupport::Concern

  def handle_create_avis(dossier:, user:, params:, success_path:, error_template:, avis_source: nil)
    emails = Array(params[:emails]).map(&:strip).map(&:downcase).compact_blank

    if emails.empty?
      @new_avis = Avis.new(params)
      email_label = User.human_attribute_name(:email)
      flash.now[:alert] = format(I18n.t('errors.format'), attribute: email_label, message: I18n.t('errors.messages.blank'))
      render error_template, status: :unprocessable_content
      return
    end

    result = CreateAvisService.call(
      dossier: dossier,
      instructeur_or_expert: user,
      batch: false,
      params: params,
      avis_source: avis_source
    )

    if result.sent_emails.any?
      if result.sent_emails.count < 5
        flash[:notice] = "Une demande d’avis a été envoyée à #{result.sent_emails.join(', ')}"
      else
        flash[:notice] = "Une demande d’avis a été envoyée à #{result.sent_emails.count} destinataires"
      end
    end

    if result.failed_emails.any?
      @new_avis = result.avis

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
