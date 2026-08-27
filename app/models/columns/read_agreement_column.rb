# frozen_string_literal: true

class Columns::ReadAgreementColumn < Columns::DossierColumn
  def initialize(procedure_id:)
    super(
      procedure_id:,
      table: nil,
      column: nil,
      label: "Décision vue par l’usager ?",
      type: :boolean,
      displayable: false
    )
  end

  def value(dossier) = dossier.accuse_lecture_agreement_at

  def filtered_ids(dossiers, filter)
    filtered_ids_for_values(dossiers, filter[:value])
  end

  def filtered_ids_for_values(dossiers, values)
    return dossiers.ids if values.blank?
    return dossiers.ids if values.include?("true") && values.include?("false")

    if values == ["true"]
      dossiers.where.not(accuse_lecture_agreement_at: nil).ids
    elsif values == ["false"]
      dossiers.where(accuse_lecture_agreement_at: nil).ids
    else
      dossiers.ids
    end
  end
end
