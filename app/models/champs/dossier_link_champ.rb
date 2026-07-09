# frozen_string_literal: true

class Champs::DossierLinkChamp < Champ
  validate :value_integerable, if: -> { value.present? }, on: :prefill
  validates_with DossierLinkValidator, if: -> { should_validate_in_current_context? && value.present? }

  private

  def value_integerable
    Integer(value)
  rescue ArgumentError
    errors.add(:value, :not_integerable)
  end
end
