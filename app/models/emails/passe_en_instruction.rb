# frozen_string_literal: true

module Emails
  class PasseEnInstruction < EmailTemplate
    SLUG = "passe_en_instruction"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/passe_en_instruction"
    DISPLAYED_NAME = I18n.t('activerecord.models.email.passe_en_instruction.under_instruction')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.email.passe_en_instruction.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:en_instruction)
  end
end
