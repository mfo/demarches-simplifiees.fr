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
    #
    # Les exclusions sont exprimées en NOT EXISTS corrélés (et non en
    # `NOT IN (sous-requête)`) pour rester bornées à la ligne candidate : un
    # `NOT IN` balaierait toutes les corrections / attentes de réponse de la
    # plateforme, ce qui rend le filtre très lent sur une base volumineuse.
    scope :with_unread_messages_for_user, -> {
      joins(:commentaires)
        .merge(Commentaire.sent_by_agent.unread_by_recipient)
        .where.not(
          DossierPendingResponse
            .where("dossier_pending_responses.dossier_id = dossiers.id")
            .where(responded_at: nil)
            .arel.exists
        )
        .where.not(
          DossierCorrection
            .where("dossier_corrections.dossier_id = dossiers.id")
            .where(resolved_at: nil)
            .where(dossiers: { state: Dossier.states.fetch(:en_construction) })
            .arel.exists
        )
        .distinct
    }
  end
end
