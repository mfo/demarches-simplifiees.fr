# frozen_string_literal: true

module Mutations
  # The mutations editing the draft revision of a démarche. They hold the
  # GraphQL contract only: the revision does the edit and words the refusals.
  class DemarcheBrouillonMutation < Mutations::BaseMutation
    class InvalidId < StandardError; end

    argument :demarche, Types::DemarcheDescriptorType::FindDemarcheInput, "La démarche", required: true

    field :errors, [Types::ValidationErrorType], null: true

    def resolve(demarche:, **args)
      demarche_number = demarche.number.presence || ApplicationRecord.id_from_typed_id(demarche.id)
      procedure = Procedure.find_by(id: demarche_number)

      if procedure.blank? || !context.authorized_demarche?(procedure)
        return { errors: [I18n.t('graphql.mutations.demarche_brouillon.demarche_not_found', number: demarche_number)] }
      end

      result = edit(procedure.draft_revision, **args)

      if result.success?
        success_payload(procedure, result)
      else
        { errors: result.errors }
      end
    rescue InvalidId => e
      { errors: [e.message] }
    end

    private

    # Editing a form is a scope of its own: a dossier-only token is refused, even with write access.
    def ready?(**args)
      return false, { errors: [I18n.t('graphql.mutations.demarche_brouillon.form_scope_required')] } unless context.form_write?

      authorized_before_load?(**args)
    end

    # The id a ChampDescriptor exposes is the stable id of the champ, typed.
    def stable_id_from(id)
      type, stable_id = GraphQL::Schema::UniqueWithinType.decode(id)
      raise InvalidId if type != 'Champ' || stable_id.blank?

      stable_id
    rescue StandardError # whatever the decoding makes of an id that is not one
      raise InvalidId, I18n.t('graphql.mutations.demarche_brouillon.invalid_champ_id', id:)
    end
  end
end
