# frozen_string_literal: true

module Manager
  class SuperAdminsController < Manager::ApplicationController
    include RequiresFreshSuperAdminOtp

    before_action :set_super_admin, only: [:reset_otp_edit, :reset_otp]
    before_action :refuse_self_otp_reset, only: [:reset_otp_edit, :reset_otp]
    before_action :verify_fresh_super_admin_otp!, only: [:reset_otp]

    def reset_otp_edit
    end

    def reset_otp
      @super_admin.disable_otp!

      flash[:notice] = t('.success', email: @super_admin.email)
      redirect_to manager_super_admin_path(@super_admin)
    end

    private

    def set_super_admin
      @super_admin = SuperAdmin.find(params[:id])
    end

    def refuse_self_otp_reset
      return if @super_admin != current_super_admin

      flash[:alert] = t('manager.super_admins.self_otp_reset_forbidden')
      redirect_to manager_super_admin_path(current_super_admin)
    end
  end
end
