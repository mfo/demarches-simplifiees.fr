# frozen_string_literal: true

class Champs::FranceConnectChamp < Champ
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
end
