# frozen_string_literal: true

class TypesDeChamp::FranceConnectTypeDeChamp < TypesDeChamp::TypeDeChampBase
  REGISTRY = {
    quotient_familial: {
      columns: Columns::FranceConnectChampColumn::QUOTIENT_FAMILIAL_COLUMNS,
    },
    etudiant_boursier: {
      columns: Columns::FranceConnectChampColumn::ETUDIANT_BOURSIER_COLUMNS,
    },
    aah: {
      columns: Columns::FranceConnectChampColumn::AAH_COLUMNS,
    },
    aeeh: {
      columns: Columns::FranceConnectChampColumn::AEEH_COLUMNS,
    },
  }

  def config
    REGISTRY.fetch(type_champ.to_sym)
  end

  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def champ_blank?(champ)
    return true if champ.fetched? && champ.fc_data_approved?.nil?
    return false if champ.fc_data_correct?

    if !champ.fetched? || champ.fc_data_incorrect?
      champ.piece_justificative_file.blank?
    end
  end

  def champ_value_for_export(champ, path = :value)
    ''
  end

  def columns(procedure_id:, displayable: true, prefix: nil)
    config[:columns].map do |label, jsonpath, type|
      Columns::FranceConnectChampColumn.new(
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
