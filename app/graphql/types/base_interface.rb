# frozen_string_literal: true

module Types
  module BaseInterface
    include GraphQL::Schema::Interface

    definition_methods do
      include ScopeVisibility
    end

    field_class BaseField
  end
end
