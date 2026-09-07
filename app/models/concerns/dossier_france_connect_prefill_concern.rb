# frozen_string_literal: true

module DossierFranceConnectPrefillConcern
  extend ActiveSupport::Concern

  def assign_for_tiers(will_be_for_tiers, identity_source: IdentityPrefillSource.new(dossier: self))
    self.for_tiers = will_be_for_tiers

    return if identity_source.none?

    if will_be_for_tiers
      prefill_mandataire_from(identity_source)
      reset_individual_for_tiers
    else
      prefill_individual_from(identity_source)
    end
  end

  def prefill_individual_from(identity_source)
    case identity_source.resolved
    when :france_connect
      fc_info = identity_source.france_connect_information
      individual.assign_attributes(
        nom: fc_info.family_name,
        prenom: fc_info.given_name,
        gender: fc_info.gender == 'female' ? Individual::GENDER_FEMALE : Individual::GENDER_MALE
      )
    when :pro_connect
      pc_info = identity_source.pro_connect_information
      # ProConnect ne fournit pas de civilité : gender laissé éditable.
      individual.assign_attributes(nom: pc_info.usual_name, prenom: pc_info.given_name)
    end
  end

  def prefill_champs_from_france_connect(updated_by:)
    return if for_tiers?
    return if !france_connected_with_one_identity?

    fc_info = user.france_connect_informations.first
    return if fc_info.birthdate.blank?

    revision.public_root_type_de_champs.each do |tdc|
      next if !tdc.date?
      next if !tdc.prefill_with_france_connect_information?

      champ = champ_for_update(tdc, updated_by:)
      next if champ.value.present?

      champ.prefilling_from_france_connect_information = true
      champ.value = fc_info.birthdate.iso8601
      champ.data ||= {}
      champ.data["prefilled_from_france_connect_information"] = true
      champ.save!
    end
  end

  def reset_champs_from_france_connect(updated_by:)
    return if !for_tiers?

    revision.public_root_type_de_champs.filter { it.date? && it.prefill_with_france_connect_information? }.each do |tdc|
      champ = champ_for_update(tdc, updated_by:)
      next if !champ.prefilled_from_france_connect_information?

      champ.value = nil
      champ.data = nil
      champ.save!
    end
  end

  private

  def prefill_mandataire_from(identity_source)
    case identity_source.resolved
    when :france_connect
      fc_info = identity_source.france_connect_information
      self.mandataire_first_name = fc_info.given_name
      self.mandataire_last_name = fc_info.family_name
    when :pro_connect
      pc_info = identity_source.pro_connect_information
      self.mandataire_first_name = pc_info.given_name
      self.mandataire_last_name = pc_info.usual_name
    end
  end

  def reset_individual_for_tiers
    individual.assign_attributes(
      nom: nil,
      prenom: nil,
      gender: nil,
      birthdate: nil
    )
  end
end
