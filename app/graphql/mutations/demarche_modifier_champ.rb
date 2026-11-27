# frozen_string_literal: true

module Mutations
  class DemarcheModifierChamp < Mutations::DemarcheBrouillonMutation
    description "Modifier un champ du brouillon d’une démarche. La révision publiée n’est pas modifiée. Le type d’un champ déjà publié ne peut devenir qu’un type dans lequel les dossiers déposés restent lisibles."

    argument :champ_id, ID, "Le champ à modifier.", required: true
    argument :label, String, "Le libellé du champ.", required: false
    argument :description, String, "La description du champ.", required: false
    argument :required, Boolean, "Est-ce que le champ est obligatoire ?", required: false
    argument :type, Types::ChampDescriptorType::TypeDeChampType, "Le nouveau type du champ.", required: false
    argument :options, GraphQL::Types::JSON, "Les options propres au type du champ. Les options non citées sont conservées.", required: false

    field :champ_descriptor, Types::ChampDescriptorType, "Le champ modifié, tel que le décrit le brouillon de la démarche.", null: true

    private

    def success_payload(procedure, result) = { champ_descriptor: procedure.draft_revision.type_de_champ(result.stable_id) }

    def edit(revision, champ_id:, label: nil, description: nil, required: nil, type: nil, options: nil)
      revision.update_type_de_champ_checked(stable_id_from(champ_id), libelle: label, description:, mandatory: required, type_champ: type&.to_s, options:)
    end
  end
end
