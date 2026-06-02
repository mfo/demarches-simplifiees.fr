# frozen_string_literal: true

class Columns::GeoJSONColumn < Columns::ChampColumn
  private

  def typed_value(champ)
    champ.to_feature_collection
  end
end
