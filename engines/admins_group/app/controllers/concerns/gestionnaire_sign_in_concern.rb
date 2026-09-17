# frozen_string_literal: true

# Everything ApplicationController knows about signing in as a gestionnaire, a
# profile that only exists on the instances enabling the "groupe gestionnaire"
# feature (config.ds_admins_group_enabled).
module GestionnaireSignInConcern
  extend ActiveSupport::Concern

  included do
    helper_method :current_gestionnaire, :gestionnaire_signed_in?
  end

  def current_gestionnaire
    current_user&.gestionnaire
  end

  def gestionnaire_signed_in?
    current_gestionnaire.present?
  end

  # Unlike the other profiles, this one does not store the requested location:
  # a gestionnaire lands back on their groups list after signing in.
  def authenticate_gestionnaire!
    if !gestionnaire_signed_in?
      redirect_to new_user_session_path
    end
  end
end
