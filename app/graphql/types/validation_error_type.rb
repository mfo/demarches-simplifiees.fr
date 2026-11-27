# frozen_string_literal: true

module Types
  class ValidationErrorType < Types::BaseObject
    description "Éreur de validation"

    # Only carries a message, which the form mutations report too.
    form_structure!

    field :message, String, "A description of the error", null: false

    def message
      object
    end
  end
end
