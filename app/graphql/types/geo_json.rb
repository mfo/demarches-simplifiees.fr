# frozen_string_literal: true

module Types
  class GeoJSON < Types::BaseObject
    class CoordinatesType < Types::BaseScalar
      description "GeoJSON coordinates"

      def self.coerce_result(ruby_value, context)
        ruby_value
      end
    end

    field :type, String, null: false
    field :coordinates, CoordinatesType, null: false

    class GeometryType < Types::BaseObject
      graphql_name "GeoJSONGeometry"
      field :type, String, null: false
      field :coordinates, CoordinatesType, null: false
    end

    class FeaturePropertiesType < Types::BaseObject
      graphql_name "GeoJSONFeatureProperties"
      field :description, String, null: true
    end

    class FeatureType < Types::BaseObject
      graphql_name "GeoJSONFeature"
      field :geometry, Types::GeoJSON::GeometryType, null: false
      field :properties, Types::GeoJSON::FeaturePropertiesType, null: false
    end
  end
end
