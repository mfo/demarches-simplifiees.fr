# frozen_string_literal: true

module DossierMessagerieConcern
  extend ActiveSupport::Concern

  included do
    has_many :unread_messages_for_user,
      -> { sent_by_agent.unread_by_recipient },
      class_name: 'Commentaire',
      inverse_of: :dossier

    # Dossiers avec un message d'agent non lu, en excluant ceux dont le badge
    # prioritaire est « à corriger » (pending_correction) ou « en attente de
    # réponse » (pending_response). Équivalent SQL de la règle d'affichage
    # DossierHelper#show_new_message_notification?, utilisé par le filtre
    # « nouveau message » de la liste des dossiers.
    scope :with_unread_messages_for_user, -> {
      joins(:commentaires)
        .merge(Commentaire.sent_by_agent.unread_by_recipient)
        .where.not(id: with_pending_responses.select(:id))
        .where.not(id: state_en_construction.with_pending_corrections.select(:id))
        .distinct
    }
  end
end
