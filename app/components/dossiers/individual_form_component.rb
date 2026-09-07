# frozen_string_literal: true

class Dossiers::IndividualFormComponent < ApplicationComponent
  delegate :for_tiers?, to: :@dossier

  def initialize(dossier:, identity_source: IdentityPrefillSource.new(dossier:))
    @dossier = dossier
    @identity_source = identity_source
  end

  def email_notifications?(individual)
    individual.object.notification_method == Individual.notification_methods[:email]
  end

  def can_personal_data_be_transmitted?
    @dossier.has_france_connect_type_de_champ? && current_user.france_connected_with_one_identity?
  end

  def individual_field_locked?(field) = @identity_source.individual_field_locked?(field)

  def individual_identity_locked? = @identity_source.individual_locked_fields.any?

  def mandataire_identity_locked? = @identity_source.mandataire_locked?

  private

  def back_url
    helpers.commencer_path(path: @dossier.procedure.path)
  end
end
