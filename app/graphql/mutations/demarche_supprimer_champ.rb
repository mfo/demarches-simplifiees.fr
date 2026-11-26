# frozen_string_literal: true

module Mutations
  class DemarcheSupprimerChamp < Mutations::DemarcheBrouillonMutation
    description "Supprimer un champ du brouillon d’une démarche. Un bloc répétable est supprimé avec ses champs."

    argument :champ_id, ID, "Le champ à supprimer.", required: true

    field :demarche, Types::DemarcheDescriptorType, null: true

    private

    def success_payload(procedure, _result) = { demarche: procedure }

    def edit(revision, champ_id:)
      revision.remove_type_de_champ_checked(stable_id_from(champ_id))
    end
  end
end
