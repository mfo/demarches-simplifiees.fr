# frozen_string_literal: true

module Emails
  class Accepte < ApplicationRecord
    include EmailTemplateConcern
    self.table_name = "closed_mails" # legacy table, gone at the STI switch

    belongs_to :procedure, optional: false

    SLUG = "accepte"
    DISPLAYED_NAME = I18n.t('activerecord.models.email.accepte.acceptance_acknowledgment')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.email.accepte.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:accepte)

    def self.default_template_name_for_procedure(procedure)
      attestation_acceptation_template = procedure.attestation_acceptation_template
      if attestation_acceptation_template&.activated?
        "notification_mailer/default_templates/accepte_avec_attestation"
      else
        "notification_mailer/default_templates/accepte"
      end
    end
  end
end
