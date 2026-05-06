# frozen_string_literal: true

require 'rails_helper'

describe SuperAdminsController, type: :controller do
  let(:password) { '{My-$3cure-p4ssWord}' }

  describe 'PUT #enable_otp' do
    before { sign_in super_admin }

    context 'when the super admin has not enrolled OTP yet' do
      let(:super_admin) { create(:super_admin, otp_required_for_login: false, password:) }

      it 'rotates the secret and signs out when the current password is provided' do
        previous_secret = super_admin.otp_secret

        put :enable_otp, params: { current_password: password }

        super_admin.reload
        expect(super_admin.otp_secret).to be_present
        expect(super_admin.otp_secret).not_to eq(previous_secret)
        expect(super_admin.otp_required_for_login?).to be(true)
        expect(controller.super_admin_signed_in?).to be(false)
      end

      it 'is rejected when no current password is provided' do
        previous_secret = super_admin.otp_secret

        put :enable_otp

        super_admin.reload
        expect(super_admin.otp_secret).to eq(previous_secret)
        expect(super_admin.otp_required_for_login?).to be(false)
        expect(response).to redirect_to(edit_super_admin_otp_path)
        expect(flash[:alert]).to be_present
      end

      it 'is rejected when the current password is wrong' do
        previous_secret = super_admin.otp_secret

        put :enable_otp, params: { current_password: 'wrong-password' }

        super_admin.reload
        expect(super_admin.otp_secret).to eq(previous_secret)
        expect(super_admin.otp_required_for_login?).to be(false)
        expect(response).to redirect_to(edit_super_admin_otp_path)
        expect(flash[:alert]).to be_present
      end
    end

    context 'when the super admin already enrolled OTP' do
      let(:super_admin) { create(:super_admin, otp_required_for_login: true, password:) }

      it 'rotates the secret and signs out when the current password is provided' do
        previous_secret = super_admin.otp_secret

        put :enable_otp, params: { current_password: password }

        super_admin.reload
        expect(super_admin.otp_secret).to be_present
        expect(super_admin.otp_secret).not_to eq(previous_secret)
        expect(super_admin.otp_required_for_login?).to be(true)
        expect(controller.super_admin_signed_in?).to be(false)
      end

      it 'is rejected when the current password is wrong' do
        previous_secret = super_admin.otp_secret

        put :enable_otp, params: { current_password: 'wrong-password' }

        super_admin.reload
        expect(super_admin.otp_secret).to eq(previous_secret)
        expect(response).to redirect_to(edit_super_admin_otp_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
