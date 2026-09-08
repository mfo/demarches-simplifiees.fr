# frozen_string_literal: true

class AccountDropdownComponent < ViewComponent::Base
  attr_reader :dossier
  attr_reader :nav_bar_profile

  delegate :current_user, :current_email, :color_by_role, :multiple_devise_profile_connect?,
           :super_admin_signed_in?, :profile_home_path,
           to: :helpers

  def initialize(dossier:, nav_bar_profile:)
    @dossier = dossier
    @nav_bar_profile = nav_bar_profile
  end

  def profil_path_params
    NavBarProfile.all.include?(nav_bar_profile) ? { context: nav_bar_profile } : {}
  end

  def france_connected?
    current_user&.france_connected_with_one_identity?
  end

  def show_profile_badge?
    nav_bar_profile != :guest
  end

  # Profiles the account can switch to, least specific first.
  def switchable_profiles
    NavBarProfile.all.reverse.filter do |profile|
      profile != nav_bar_profile && helpers.public_send(:"#{profile}_signed_in?")
    end
  end

  # Both instructeur and administrateur keep the user inside the procedure they
  # are looking at, instead of sending them back to their procedures list.
  def switch_path_for(profile)
    case profile
    when :instructeur then instructeur_path
    when :administrateur then admin_path
    else profile_home_path(profile)
    end
  end

  def instructeur_path
    if controller_name == "procedures" && params[:id].present?
      instructeur_procedure_path(params[:id])
    elsif params[:procedure_id].present?
      instructeur_procedure_path(params[:procedure_id])
    else
      instructeur_procedures_path
    end
  end

  def admin_path
    if params[:procedure_id].present?
      admin_procedure_path(params[:procedure_id])
    else
      admin_procedures_path
    end
  end
end
