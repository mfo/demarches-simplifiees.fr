# frozen_string_literal: true

module Types
  # Closed by default: a type or a field is hidden from a token that cannot read
  # dossiers, unless it is explicitly opened here. Anything added later stays
  # invisible to such a token until someone opens it on purpose.
  #
  #   form_structure!        the type and all its fields describe a form, never
  #                          what an applicant or a reviewer entered
  #   form_fields :a, :b     the type is open, only the listed fields are
  module ScopeVisibility
    def form_structure!
      @form_structure = true
    end

    def form_fields(*names)
      @form_fields = names.freeze
    end

    def form_structure? = !!@form_structure

    def form_field?(name) = form_structure? || !!@form_fields&.include?(name)

    def open_to_form_tokens? = form_structure? || @form_fields.present?

    def visible?(context)
      super && (context.dossier_read? || open_to_form_tokens?)
    end
  end
end
