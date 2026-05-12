# frozen_string_literal: true

module ProConnectSessionConcern
  extend ActiveSupport::Concern

  SESSION_INFO_COOKIE_NAME = :pro_connect_session_info
  # Cookies set before mfa_at was introduced have no client-side expiry and
  # could otherwise persist indefinitely. Refuse them past this date (~1 month
  # after deploy, aligned with TRUSTED_DEVICE_PERIOD) so any remaining ones
  # are forced to renew their MFA assertion via ProConnect.
  LEGACY_COOKIE_DEADLINE = Time.zone.local(2026, 6, 13).freeze

  included do
    helper_method :logged_in_with_pro_connect?
  end

  def set_pro_connect_session_info_cookie(user_id, mfa: false)
    value = { user_id:, mfa:, mfa_at: Time.current.iso8601 }.to_json
    cookies.encrypted[SESSION_INFO_COOKIE_NAME] = {
      value:,
      expires: TrustedDeviceConcern::TRUSTED_DEVICE_PERIOD.from_now,
      secure: Rails.env.production?,
      httponly: true,
    }
  end

  def logged_in_with_pro_connect?
    pro_connect_session.present?
  end

  def pro_connect_mfa?
    info = pro_connect_session
    return false if info['mfa'] != true
    return Time.current < LEGACY_COOKIE_DEADLINE if info['mfa_at'].blank?

    Time.iso8601(info['mfa_at']) > TrustedDeviceConcern::TRUSTED_DEVICE_PERIOD.ago
  rescue ArgumentError
    false
  end

  def delete_pro_connect_session_info_cookie
    cookies.delete SESSION_INFO_COOKIE_NAME
  end

  private

  def pro_connect_session
    session = if cookies.encrypted[SESSION_INFO_COOKIE_NAME].present?
      JSON.parse(cookies.encrypted[SESSION_INFO_COOKIE_NAME])
    else
      {}
    end

    session['user_id'] == current_user.id ? session : {}
  end
end
