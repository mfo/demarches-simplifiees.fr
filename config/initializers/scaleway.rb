# frozen_string_literal: true

if ENV.key?('SCALEWAY_BALANCING_VALUE')
  ActiveSupport.on_load(:action_mailer) do
    module Scaleway
      class SMTP < ::Mail::SMTP; end
    end

    ActionMailer::Base.add_delivery_method :scaleway, Scaleway::SMTP
    ActionMailer::Base.scaleway_settings = {
      user_name: ENV.fetch("SCALEWAY_PROJECT_ID"),
      password: ENV.fetch("SCALEWAY_SECRET_KEY"),
      address: ENV.fetch("SCALEWAY_SMTP_ADDRESS", "smtp.tem.scaleway.com"),
      domain: ENV['APP_HOST'],
      port: ENV.fetch("SCALEWAY_SMTP_PORT", 587).to_i,
      authentication: :plain,
      enable_starttls_auto: true,
    }
  end
end
