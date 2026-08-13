# frozen_string_literal: true

class TypesDeChamp::CarteTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def self.category = REFERENTIEL_EXTERNE
  def self.editable_option_keys = CARTE_LAYERS
  def self.column_type = :geojson

  def estimated_fill_duration(revision)
    FILL_DURATION_LONG
  end

  def typed_champ_value_for_tag(champ, path = :value)
    return nil if path != :value
    return '' if champ.geo_areas.blank?
    ChampPresentations::CartePresentation.new(champ.geo_areas)
  end

  def typed_champ_value_for_api(champ, version: 2)
    nil
  end

  def typed_champ_value_for_export(champ, path = :value)
    champ.geo_areas.map(&:label).join("\n")
  end

  def typed_champ_blank?(champ) = champ.geo_areas.blank?

  def canonical_column(procedure_id:, displayable: true, prefix: nil)
    Columns::GeoJSONColumn.new(
      procedure_id:,
      stable_id:,
      tdc_type: type_champ,
      label: libelle_with_prefix(prefix),
      type: self.class.column_type,
      displayable: false,
      filterable: false,
      mandatory: mandatory?
    )
  end

  def columns(procedure_id:, displayable: true, prefix: nil)
    []
  end
end
