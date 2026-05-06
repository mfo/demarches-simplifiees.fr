# frozen_string_literal: true

module RequiresEnrolledSuperAdminOtp
  extend ActiveSupport::Concern

  protected

  def authenticate_super_admin!
    super

    return unless super_admin_signed_in?
    return unless SUPER_ADMIN_OTP_ENABLED
    return if current_super_admin.otp_required_for_login?

    redirect_to edit_super_admin_otp_path
  end
end
