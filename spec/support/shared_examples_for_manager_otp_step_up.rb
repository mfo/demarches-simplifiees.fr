# frozen_string_literal: true

# Shared coverage for Manager controller actions protected by
# RequiresFreshSuperAdminOtp. Callers must define:
#
#   subject         - the request closure that reads let(:otp_attempt) for the
#                     OTP code
#   action_matcher  - an RSpec matcher proving the action ran end-to-end
#                     (e.g. `change { user.reload.email }` or
#                     `have_enqueued_mail(DossierMailer, :notify_transfer)`)
#   replay_subject  - a callable issuing a second, distinct request that reuses
#                     the same OTP code; used only by the replay context
#
# Requires a super_admin built with `create(:super_admin, :with_otp)` and
# signed in by the surrounding context.
RSpec.shared_examples "a manager action gated by a fresh super-admin OTP" do
  context 'when the OTP code is missing' do
    let(:otp_attempt) { nil }

    it 'rejects the action and sets a flash error' do
      expect { subject }.not_to action_matcher
      expect(flash[:error]).to include("Code OTP invalide ou manquant")
    end
  end

  context 'when the OTP code is invalid' do
    let(:otp_attempt) { (current_otp_for(super_admin).to_i + 1).to_s.rjust(6, '0') }

    it 'rejects the action and sets a flash error' do
      expect { subject }.not_to action_matcher
      expect(flash[:error]).to include("Code OTP invalide ou manquant")
    end
  end

  context 'when the same OTP code is replayed within its drift window' do
    let(:otp_attempt) { current_otp_for(super_admin) }

    it 'accepts the first submission and rejects the replay' do
      expect { subject }.to action_matcher
      expect { replay_subject.call }.not_to action_matcher
      expect(flash[:error]).to include("Code OTP invalide ou manquant")
    end
  end

  context 'when SUPER_ADMIN_OTP_ENABLED is false' do
    let(:otp_attempt) { nil }

    before { stub_const('SUPER_ADMIN_OTP_ENABLED', false) }

    it 'performs the action without requiring an OTP code' do
      expect { subject }.to action_matcher
    end
  end
end
