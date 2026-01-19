# frozen_string_literal: true

module DossierEditConcern
  extend ActiveSupport::Concern

  private

  def update_dossier_and_compute_errors
    public_id, champ_attributes = champs_public_attributes_params.to_h.first
    champ = dossier.public_champ_for_update(public_id, updated_by: current_user.email)
    if champ.referentiel? && champ.autocomplete?
      champ_attributes = champ_attributes.merge(params.require(:dossier).require(:champs_public_attributes).require(public_id).permit(:data).to_h)
    end
    champ.assign_attributes(champ_attributes)
    champ_changed = champ.changed_for_autosave?

    # We save the dossier without validating fields, and if it is successful and the client
    # requests it, we ask for field validation errors.
    if Dossier.no_touching { champ.save }
      if champ_changed
        champ.update_timestamps if dossier.brouillon?

        if champ.has_async_external_data?
          champ.reset_external_data!
          champ.fetch_later! if champ.may_fetch_later?
        end

        if champ.used_by_routing_rules? && dossier.brouillon?
          @update_contact_information = true
          RoutingEngine.compute(dossier)
        end
      end

      if params[:validate].present? && !champ.pending?
        dossier.validate(:champs_public_value)
      end
    end
  end

  def champs_public_params
    champ_attributes = [
      :id,
      :value,
      :value_other,
      :external_id,
      :code,
      :primary_value,
      :secondary_value,
      :piece_justificative_file,
      :code_departement,
      :accreditation_number,
      :accreditation_birthdate,
      :address,
      :not_in_ban,
      :street_address,
      :city_name,
      :country_code,
      :commune_code,
      :postal_code,
      :preview_state,
      value: [],
    ]
    # Strong attributes do not support records (indexed hash); they only support hashes with
    # static keys. We create a static hash based on the available keys.
    public_ids = params.dig(:dossier, :champs_public_attributes)&.keys || []
    champs_public_attributes = public_ids.index_with { champ_attributes }
    params.require(:dossier).permit(champs_public_attributes:)
  end

  def champs_public_attributes_params
    champs_public_params.fetch(:champs_public_attributes)
  end
end
