# frozen_string_literal: true

class Manager::OtpAttemptInputComponent < ApplicationComponent
  # `id` lets a page render several inputs (e.g. one per inline form) without
  # duplicating the DOM id; the submitted param name stays `otp_attempt`.
  def initialize(id: "otp_attempt")
    @id = id
  end

  attr_reader :id

  def render?
    SUPER_ADMIN_OTP_ENABLED
  end
end
