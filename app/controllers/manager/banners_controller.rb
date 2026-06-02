module Manager
  class BannersController < Manager::ApplicationController
    helper ManagerBannerIconsHelper

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
