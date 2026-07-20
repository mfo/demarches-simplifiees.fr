# frozen_string_literal: true

class Champs::FranceConnectChamp < ChampData
  REFRESH_DELAY = 24.hours

  attr_accessor :preview_state

  def fc_data_approved? = ActiveModel::Type::Boolean.new.cast(value)

  def fc_data_correct?
    fetched? && fc_data_approved?
  end

  def fc_data_incorrect?
    fetched? && fc_data_approved? == false
  end

  def fc_data_not_found?
    external_error? && self.fetch_external_data_exceptions.first&.code == 404
  end

  def ready_for_external_call?
    dossier.user_from_france_connect? && !dossier.for_tiers? && dossier.procedure.for_individual? && !dossier.for_procedure_preview?
  end

  def fetch_external_data
    fci = dossier.user.france_connect_informations.first
    api = APIParticulier::API.new(procedure, type_champ)
    api.call_with_fci(fci)
  end

  def update_external_data!(data)
    hash = {
      data: { api_part: data },
      value_json: { api_part: extract_value_json(data:) },
    }
    super(hash)
  end

  def clear_piece_justificative
    if fc_data_correct? && self.piece_justificative_file.attached?
      self.piece_justificative_file.purge_later
    end
  end

  def libelle
    if fc_data_correct?
      ""
    elsif fc_data_incorrect? || external_error? || idle?
      I18n.t('france_connect_champ.libelle.piece_justificative', type_champ: type_champ_for_libelle)
    else
      I18n.t('france_connect_champ.libelle.default', type_champ: type_champ_for_libelle.upcase_first)
    end
  end

  private

  def extract_value_json(data:)= data

  def type_champ_for_libelle
    I18n.t("france_connect_champ.type_champ.#{type_champ}")
  end
end
