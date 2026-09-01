# frozen_string_literal: true

RSpec.describe ExpertMailer, type: :mailer do
  describe '.send_dossier_decision' do
    let(:mail) { described_class.send_dossier_decision(avis.answered).deliver_now }

    it 'is addressed to the expert who gave the avis' do
      expect(mail.to).to eq([experts.default.email])
    end

    it 'announces the decision in the subject' do
      decision = I18n.t('users.dossiers.attestation_depot.states.accepte')

      expect(mail.subject).to eq("Dossier n° #{dossiers.accepte.id} a été #{decision} - #{procedures.individual.libelle}")
    end

    it 'renders the send_dossier_decision template' do
      body = mail.html_part.body.to_s

      expect(body).to include(dossiers.accepte.id.to_s)
      expect(body).to include(I18n.t('users.dossiers.attestation_depot.states.accepte'))
    end
  end

  # TODO: remove alongside the ExpertMailer.send_dossier_decision_v2 shim, once
  # the mail delivery jobs enqueued under the old action name have drained.
  describe '.send_dossier_decision_v2 (compat shim)' do
    it 'delivers the same mail as the new action name' do
      shimmed = described_class.send_dossier_decision_v2(avis.answered).deliver_now
      renamed = described_class.send_dossier_decision(avis.answered).deliver_now

      expect(shimmed.to).to eq(renamed.to)
      expect(shimmed.subject).to eq(renamed.subject)
      expect(shimmed.html_part.body.to_s).to eq(renamed.html_part.body.to_s)
    end

    it 'lets a delivery job enqueued under the old action name go through' do
      expect { PriorizedMailDeliveryJob.perform_now('ExpertMailer', 'send_dossier_decision_v2', 'deliver_now', args: [avis.answered]) }
        .to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end
end
