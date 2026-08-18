# frozen_string_literal: true

module Emails
  class ClasseSansSuite < ApplicationRecord
    include EmailTemplateConcern
    self.table_name = "without_continuation_mails" # legacy table, gone at the STI switch

    belongs_to :procedure, optional: false

    SLUG = "classe_sans_suite"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/classe_sans_suite"
    DISPLAYED_NAME = I18n.t('activerecord.models.email.classe_sans_suite.closure_acknowledgment')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.email.classe_sans_suite.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:sans_suite)
  end
end
