# frozen_string_literal: true

describe GroupeGestionnaireUserConcern do
  describe 'invite_gestionnaire!' do
    let(:administrateur) { administrateurs.default }
    let(:user) { administrateur.user }
    let(:groupe_gestionnaire) { create(:groupe_gestionnaire) }
    let(:mailer_double) { double('mailer', deliver_later: true) }

    before do
      allow(GroupeGestionnaireMailer).to receive(:invite_gestionnaire).and_return(mailer_double)
      allow(GroupeGestionnaireMailer).to receive(:invite_gestionnaire_via_pro_connect).and_return(mailer_double)
    end

    subject { user.invite_gestionnaire!(groupe_gestionnaire) }

    it 'receives an invitation to choose a password' do
      subject

      expect(GroupeGestionnaireMailer).to have_received(:invite_gestionnaire).with(user, kind_of(String), groupe_gestionnaire)
    end

    context 'when the administrateur must use ProConnect' do
      before do
        allow(ProConnectService).to receive(:enabled?).and_return(true)
        administrateur.update!(pro_connect_required_at: Time.zone.now)
      end

      it 'receives a ProConnect invitation without any reset password token' do
        expect { subject }.not_to change { user.reload.reset_password_token }

        expect(GroupeGestionnaireMailer).to have_received(:invite_gestionnaire_via_pro_connect).with(user, groupe_gestionnaire)
        expect(GroupeGestionnaireMailer).not_to have_received(:invite_gestionnaire)
      end
    end
  end

  describe '.create_or_promote_to_gestionnaire' do
    let(:email) { 'inst1@gmail.com' }
    let(:password) { 'un super p1ssw0rd !' }

    subject { User.create_or_promote_to_gestionnaire(email, password) }

    it 'creates a gestionnaire with unverified email' do
      user = subject
      expect(user.email_verified_at).to be_nil
      expect(user.reload.gestionnaire?).to be true
    end
  end
end
