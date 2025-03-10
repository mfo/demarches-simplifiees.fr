# frozen_string_literal: true

class EditableChamp::AddressComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-select'
  end

  def react_props
    react_input_opts(id: @champ.input_id,
      class: 'fr-mt-1w',
      name: @form.field_name(:value),
      selected_key: @champ.selected_key,
      items: @champ.selected_items,
      loader: data_sources_data_source_adresse_path,
      minimum_input_length: 2,
      is_disabled: !@champ.ban?)
  end

  def commune_react_props
    {
      id: @champ.input_id + "-commune",
      class: 'fr-mt-1w fr-mb-0',
      name: @form.field_name(:commune_code),
      selected_key: @champ.commune_selected_key,
      items: @champ.commune_selected_items,
      loader: data_sources_data_source_commune_path(with_combined_code: true),
      limit: 20,
      minimum_input_length: 2
    }
  end

  def pays_options
    APIGeoService.countries.map { [_1[:name], _1[:code]] }
  end
end
