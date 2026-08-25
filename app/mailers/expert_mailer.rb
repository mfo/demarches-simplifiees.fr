# frozen_string_literal: true

class ExpertMailer < ApplicationMailer
  layout 'mailers/layout'

  def send_dossier_decision_v2(avis)
    @avis = avis
    @dossier = @avis.dossier
    email = @avis.expert.email
    @decision = decision_dossier(@dossier)
    subject = t('expert_mailer.send_dossier_decision.subject', dossier_id: @dossier.id, decision: @decision, libelle: @dossier.procedure.libelle)

    mail(template_name: 'send_dossier_decision', to: email, subject: subject)
  end

  def self.critical_email?(action_name)
    false
  end

  private

  def decision_dossier(dossier)
    if dossier.accepte?
      t('users.dossiers.attestation_depot.states.accepte')
    elsif dossier.sans_suite?
      t('users.dossiers.attestation_depot.states.sans_suite')
    elsif dossier.refuse?
      t('users.dossiers.attestation_depot.states.refuse')
    end
  end
end
