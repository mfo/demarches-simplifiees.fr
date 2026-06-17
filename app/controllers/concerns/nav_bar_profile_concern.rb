# frozen_string_literal: true

module NavBarProfileConcern
  extend ActiveSupport::Concern

  # Override this method on controller basis for more precise context or custom logic
  def nav_bar_profile
  end

  def fallback_nav_bar_profile
    return :guest if current_user.blank?

    nav_bar_profile_from_referrer || default_nav_bar_profile_for_user
  end

  private

  def nav_bar_user_or_guest
    current_user ? :user : :guest
  end

  # Shared controllers (search, errors, release notes…) don't have specific context
  # Simple attempt to try to re-use the profile from the previous page
  # so user does'not feel lost.
  def nav_bar_profile_from_referrer
    # detect context from referer, simple (no detection when refreshing the page)
    # the profile is declared as a route default (see config/routes.rb)
    # and recognize_path ignores the query parameters
    Rails.application.routes.recognize_path(request&.referer)[:nav_bar_profile]
  rescue StandardError => e # bad referer raises in recognize_path; don't fail the request
    Sentry.capture_exception(e)

    nil
  end

  # Fallback for shared controllers from user account
  # to the more relevant profile.
  def default_nav_bar_profile_for_user
    return :gestionnaire if current_user.gestionnaire?
    return :administrateur if current_user.administrateur?
    return :instructeur if current_user.instructeur?
    return :expert if current_user.expert?

    :user
  end
end
