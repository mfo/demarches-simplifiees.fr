# frozen_string_literal: true

class TypesDeChamp::CommuneTypeDeChamp < TypesDeChamp::TypeDeChampBase
  include AddressableColumnConcern

  def champ_value_for_export(champ, path = :value)
    case path
    when :value
      champ_value(champ)
    when :departement
      champ.departement_code_and_name || ''
    when :code
      champ.code || ''
    end
  end

  def champ_value_for_tag(champ, path = :value)
    case path
    when :value
      champ_value(champ)
    when :departement
      champ.departement_code_and_name || ''
    when :code
      champ.code || ''
    end
  end

  def champ_value(champ)
    champ.code_postal? ? "#{champ.name} (#{champ.code_postal})" : champ.name
  end

  def columns(procedure:, displayable: true, prefix: nil)
    super
      .concat(addressable_columns(procedure:, displayable:, prefix:))
      .concat(legacy_columns(procedure:, prefix:))
  end

  def info_columns(procedure:)
    Dossiers::CommuneComponent.data_labels
  end

  private

  # Anciennes colonnes JSONPath conservées pour rester résolvables par les
  # ProcedurePresentation / exports / colonnes graphql persistées avant la bascule sur AddressableColumnConcern.
  def legacy_columns(procedure:, prefix:)
    [
      ['code postal (5 chiffres)', '$.code_postal', :text],
      ['département', '$.code_departement', :number],
    ].map do |(label, jsonpath, type)|
      Columns::JSONPathColumn.new(
        procedure_id: procedure.id,
        stable_id:,
        tdc_type: type_champ,
        label: "#{libelle_with_prefix(prefix)} - #{label}",
        jsonpath:,
        displayable: false,
        filterable: false,
        type:,
        mandatory: mandatory?
      )
    end
  end

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Code INSEE)",
      description: "#{description} (Code INSEE)",
      path: :code,
      maybe_null: public? && !mandatory?,
    })
    paths.push({
      libelle: "#{libelle} (Département)",
      description: "#{description} (Département)",
      path: :departement,
      maybe_null: public? && !mandatory?,
    })
    paths
  end
end
