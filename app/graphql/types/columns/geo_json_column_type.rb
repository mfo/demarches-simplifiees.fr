# frozen_string_literal: true

module Types::Columns
  class GeoJSONColumnType < Types::BaseObject
    implements Types::ColumnType

    field :value, [Types::GeoJSON::FeatureType], null: false, extras: [:parent]

    def value(parent:)
      dataloader.with(Sources::Association, :geo_areas).load(parent) if parent.is_a?(ChampData)

      feature_collection = object.value(parent)
      return [] if feature_collection.blank?
      feature_collection[:features]
    end
  end
end
