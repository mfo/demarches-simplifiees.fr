# frozen_string_literal: true

module Manager
  class BannersController < Manager::ApplicationController
    include RequiresFreshSuperAdminOtp

    before_action :verify_fresh_super_admin_otp!, only: [:update]

    def index
      @banners = Banner.order(:id)
    end

    def update
      @banner = Banner.find(params[:id])
      @banner.update(banner_params)
      redirect_to manager_banners_path, notice: "Bannière mise à jour"
    end

    private

    def banner_params
      params.require(:banner).permit(:content)
    end
  end
end
