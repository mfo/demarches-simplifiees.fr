# frozen_string_literal: true

module Types
  class BaseUnion < GraphQL::Schema::Union
    extend ScopeVisibility
  end
end
