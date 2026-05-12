# frozen_string_literal: true

class Champs::EmailChamp < Champs::TextChamp
  normalizes :value, with: -> (value) { value.present? ? EmailSanitizableConcern::EmailSanitizer.sanitize(value) : value }

  validates :value, allow_blank: true, strict_email: true, if: :should_validate_in_current_context?
end
