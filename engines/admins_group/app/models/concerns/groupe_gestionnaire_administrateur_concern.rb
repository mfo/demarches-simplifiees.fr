# frozen_string_literal: true

# Everything Administrateur knows about the "groupe gestionnaire" feature, which
# only a few instances enable (config.ds_admins_group_enabled).
module GroupeGestionnaireAdministrateurConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :groupe_gestionnaire, optional: true
    has_many :commentaire_groupe_gestionnaires, as: :sender
  end

  def unread_commentaires?
    commentaire_groupe_gestionnaires.last && (commentaire_seen_at.nil? || commentaire_seen_at < commentaire_groupe_gestionnaires.last.created_at)
  end

  def mark_commentaire_as_seen
    update(commentaire_seen_at: Time.zone.now)
  end
end
