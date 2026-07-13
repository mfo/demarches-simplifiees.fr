# frozen_string_literal: true

class TypesDeChamp::QuotientFamilialTypeDeChamp < TypesDeChamp::FranceConnectTypeDeChamp
  def columns(procedure_id:, displayable: true, prefix: nil)
    Columns::QuotientFamilialColumn::QUOTIENT_FAMILIAL_COLUMNS.map do |label, jsonpath, type|
      Columns::QuotientFamilialColumn.new(
        procedure_id:,
        stable_id:,
        tdc_type: type_champ,
        label: "#{libelle_with_prefix(prefix)} – #{label}",
        jsonpath:,
        displayable:,
        type:,
        mandatory: mandatory?
      )
    end
  end
end
