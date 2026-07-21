# frozen_string_literal: true

module Emails
  class Refuse < EmailTemplate
    SLUG = "refuse"
    DISPLAYED_NAME = I18n.t('activerecord.models.email.refuse.refusal_acknowledgment')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.email.refuse.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:refuse)

    def actions_for_dossier(dossier)
      [EmailTemplate::Actions::REPLY, EmailTemplate::Actions::SHOW]
    end

    def self.default_template_name_for_procedure(procedure)
      attestation_refus_template = procedure.attestation_refus_template
      if attestation_refus_template&.activated?
        "notification_mailer/default_templates/refuse_avec_attestation"
      else
        "notification_mailer/default_templates/refuse"
      end
    end
  end
end
