# frozen_string_literal: true

# Renders one message of a groupe gestionnaire conversation.
#
# Sibling of Dossiers::MessageComponent, which renders the messagerie of a
# dossier. The two look alike but share no domain: a CommentaireGroupeGestionnaire
# has no dossier, no correction, no pending response and no attachment.
class GroupeGestionnaire::MessageComponent < GroupeGestionnaire::BaseComponent
  def initialize(commentaire:, connected_user:, groupe_gestionnaire:, messagerie_seen_at: nil, heading_level: 'h2')
    @commentaire = commentaire
    @connected_user = connected_user
    @groupe_gestionnaire = groupe_gestionnaire
    @messagerie_seen_at = messagerie_seen_at
    @heading_level = heading_level
  end

  attr_reader :commentaire, :connected_user, :groupe_gestionnaire, :messagerie_seen_at, :heading_level

  private

  def commentaire_issuer
    issuer = commentaire.gestionnaire_id ? commentaire.gestionnaire_email : commentaire.sender_email

    if commentaire.sent_by?(connected_user)
      "[#{t('.you')}] #{issuer}"
    else
      issuer
    end
  end

  def commentaire_date
    I18n.l(commentaire.created_at, format: :messagerie_date)
  end

  def show_delete_button?
    commentaire.soft_deletable?(connected_user)
  end

  def delete_url
    gestionnaire_groupe_gestionnaire_commentaire_path(groupe_gestionnaire, commentaire, statut: params[:statut])
  end

  def highlight?
    commentaire.persisted? && (messagerie_seen_at.nil? || messagerie_seen_at < commentaire.created_at)
  end

  def scroll_to_target
    if highlight?
      { scroll_to_target: 'to' }
    end
  end
end
