# frozen_string_literal: true

class GeoJSONValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if options[:allow_nil] == false && value.nil?
      record.errors.add(attribute, :blank)
    end

    if value.present? && !GeojsonService.valid_schema?(value)
      record.errors.add(attribute, :invalid_geometry)
    end

    if value.present? && !GeojsonService.valid_wgs84_coordinates?(value)
      record.errors.add(attribute, :invalid_crs)
    end
  end
end
