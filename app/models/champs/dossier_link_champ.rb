# frozen_string_literal: true

class Champs::DossierLinkChamp < Champ
  validates_with DossierLinkValidator, if: -> { should_validate_in_current_context? && value.present? }
end
