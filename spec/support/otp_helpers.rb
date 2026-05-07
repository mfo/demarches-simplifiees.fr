# frozen_string_literal: true

module OtpHelpers
  def current_otp_for(super_admin)
    ROTP::TOTP.new(super_admin.otp_secret).now
  end
end

RSpec.configure do |config|
  config.include OtpHelpers, type: :controller
  config.include OtpHelpers, type: :request
end
