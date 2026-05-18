# frozen_string_literal: true

class Manager::OtpAttemptInputComponent < ApplicationComponent
  def render?
    SUPER_ADMIN_OTP_ENABLED
  end
end
