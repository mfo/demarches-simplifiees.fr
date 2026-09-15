# frozen_string_literal: true

module RequiresFreshSuperAdminOtp
  extend ActiveSupport::Concern

  private

  def verify_fresh_super_admin_otp!
    return unless SUPER_ADMIN_OTP_ENABLED

    result = current_super_admin.verify_step_up_otp!(params[:otp_attempt].to_s)
    return if result == :ok

    reject_super_admin_attempt!(result) do
      flash[:error] = t("manager.fresh_otp.invalid_code")
      redirect_back_or_to(manager_root_path)
    end
  end

  # Reacts to a failed SuperAdmin credential check (see SuperAdmin#with_attempt_limit):
  # signs a locked account out, or yields to the caller otherwise.
  def reject_super_admin_attempt!(result)
    return yield unless result == :locked

    Sentry.set_tags(super_admin: current_super_admin.id)
    Sentry.capture_message("Super admin locked after too many failed attempts", extra: { action: "#{controller_path}##{action_name}" })

    sign_out(:super_admin)
    flash[:error] = t("super_admins.lockout.locked")
    redirect_to new_super_admin_session_path
  end
end
