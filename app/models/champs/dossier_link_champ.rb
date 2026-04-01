# frozen_string_literal: true

class Champs::DossierLinkChamp < Champ
  validate :value_integerable, if: -> { value.present? }, on: :prefill
  validate :dossier_exists, if: -> { should_validate_in_current_context? && value.present? }
  validate :dossier_in_allowed_procedures, if: -> { should_validate_in_current_context? && value.present? }

  private

  def dossier_exists
    if !Dossier.exists?(value)
      errors.add(:value, :not_found)
    end
  end

  def dossier_in_allowed_procedures
    return if errors.include?(:value) # dossier_exists already failed
    return if !type_de_champ.procedures_limit?

    allowed_ids = type_de_champ.dossier_link_procedure_ids
    return if allowed_ids.empty?

    if !Dossier.joins(:revision).exists?(id: value, user: dossier.user, procedure_revisions: { procedure_id: allowed_ids })
      errors.add(:value, :not_in_allowed_procedures)
    end
  end

  def value_integerable
    Integer(value)
  rescue ArgumentError
    errors.add(:value, :not_integerable)
  end
end
