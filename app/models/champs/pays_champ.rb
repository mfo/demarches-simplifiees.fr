# frozen_string_literal: true

class Champs::PaysChamp < Champs::TextChamp
  with_options if: :should_validate_in_current_context? do
    validates :external_id, inclusion: APIGeoService.countries.pluck(:code), allow_nil: true, allow_blank: false
    validates :value, inclusion: APIGeoService.countries.pluck(:name), allow_nil: true, allow_blank: false
  end

  def selected
    code || value
  end

  def value=(code)
    resolution = APIGeoService.resolve_country(code)
    self.external_id = resolution&.code
    super(resolution&.name)
  end

  def code
    external_id || APIGeoService.country_code(value)
  end

  def name
    if external_id.present?
      APIGeoService.country_name(external_id)
    else
      value.present? ? value.to_s : ''
    end
  end

  def condition_value = code
end
