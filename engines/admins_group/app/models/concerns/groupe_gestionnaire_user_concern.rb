# frozen_string_literal: true

# Everything User knows about the "groupe gestionnaire" feature, which only a
# few instances enable (config.ds_admins_group_enabled).
module GroupeGestionnaireUserConcern
  extend ActiveSupport::Concern

  included do
    has_one :gestionnaire, dependent: :destroy
  end

  class_methods do
    def create_or_promote_to_gestionnaire(email, password)
      user = User.create_or_promote_to_administrateur(email, password)

      if user.valid? && user.gestionnaire.nil?
        user.create_gestionnaire!
      end

      user
    end
  end

  def gestionnaire?
    gestionnaire.present?
  end

  def invite_gestionnaire!(groupe_gestionnaire)
    if administrateur.pro_connect_required?
      GroupeGestionnaireMailer.invite_gestionnaire_via_pro_connect(self, groupe_gestionnaire).deliver_later
    else
      GroupeGestionnaireMailer.invite_gestionnaire(self, set_reset_password_token, groupe_gestionnaire).deliver_later
    end
  end
end
