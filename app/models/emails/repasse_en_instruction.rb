# frozen_string_literal: true

module Emails
  class RepasseEnInstruction < EmailTemplate
    SLUG = "repasse_en_instruction"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/repasse_en_instruction"
    DISPLAYED_NAME = I18n.t('activerecord.models.email.repasse_en_instruction.under_re_instruction')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.email.repasse_en_instruction.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:en_instruction)
  end
end
