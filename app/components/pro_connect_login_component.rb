# frozen_string_literal: true

class ProConnectLoginComponent < ApplicationComponent
  def initialize(url: nil, title: :default, heading_level: :h2)
    @url = url || Rails.application.routes.url_helpers.pro_connect_login_path
    @title = title
    @heading_level = heading_level
  end

  def render?
    ProConnectService.enabled?
  end

  private

  def resolved_title
    if @title == :default
      t('views.shared.france_connect_login.commencer_pc_title')
    else
      @title
    end
  end
end
