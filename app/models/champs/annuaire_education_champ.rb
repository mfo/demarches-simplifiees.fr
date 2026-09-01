# frozen_string_literal: true

class Champs::AnnuaireEducationChamp < Champs::TextChamp
  def has_async_external_data?
    true
  end

  def fetch_external_data
    data = APIEducation::AnnuaireEducationAdapter.new(external_id).to_params

    if data.present?
      Success(data:)
    else
      Failure(retryable: false, error: StandardError.new('NotFound'), code: 404)
    end
  end

  def selected_items
    if external_id.present?
      [{ value: external_id, label: value }]
    else
      []
    end
  end
end
