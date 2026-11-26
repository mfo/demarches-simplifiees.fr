# frozen_string_literal: true

module Mutations
  class DemarcheDeplacerChamp < Mutations::DemarcheBrouillonMutation
    description "Déplacer un champ du brouillon d’une démarche, au sein de son bloc."

    argument :champ_id, ID, "Le champ à déplacer.", required: true
    argument :apres_id, ID, "Le champ après lequel le placer. Sans lui, le champ est placé en premier.", required: false

    field :champ_descriptor, Types::ChampDescriptorType, "Le champ déplacé, tel que le décrit le brouillon de la démarche.", null: true

    private

    def success_payload(procedure, result) = { champ_descriptor: procedure.draft_revision.type_de_champ(result.stable_id) }

    def edit(revision, champ_id:, apres_id: nil)
      revision.move_type_de_champ_checked(stable_id_from(champ_id), after_stable_id: apres_id && stable_id_from(apres_id))
    end
  end
end
