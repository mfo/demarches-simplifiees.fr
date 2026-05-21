# frozen_string_literal: true

class AddUuidToGeoArea < ActiveRecord::Migration[7.2]
  def change
    add_column :geo_areas, :uuid, :string
  end
end
