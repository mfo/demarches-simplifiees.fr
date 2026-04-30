# frozen_string_literal: true

module AddressableColumnConcern
  extend ActiveSupport::Concern

  def addressable_columns(procedure:, displayable: true, prefix: nil)
    column_specs = [
      ["Code postal (5 chiffres)", '$.postal_code', :text, [], displayable, true],
      ["Commune", '$.city_name', :text, [], displayable, true],
      ["Département", '$.department_code', :enum, APIGeoService.departement_options, displayable, true],
      ["Région", '$.region_code', :enum, APIGeoService.region_options, displayable, true],
      # legacy: kept resolvable for procedure_presentations / export_templates saved before the jsonpath fix
      ["Région", '$.region_name', :enum, APIGeoService.region_options, false, false],
    ]

    column_specs.map do |(label, jsonpath, type, options_for_select, column_displayable, column_filterable)|
      Columns::JSONPathColumn.new(
        procedure_id: procedure.id,
        stable_id:,
        tdc_type: type_champ,
        label: "#{libelle_with_prefix(prefix)} – #{label}",
        jsonpath:,
        displayable: column_displayable,
        filterable: column_filterable,
        options_for_select:,
        type:,
        mandatory: mandatory?
      )
    end
  end
end
