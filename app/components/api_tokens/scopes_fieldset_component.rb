# frozen_string_literal: true

module APITokens
  class ScopesFieldsetComponent < ApplicationComponent
    def initialize(selected:, error: nil)
      @selected = selected
      @error = error
    end

    private

    attr_reader :selected, :error

    def scope_t(scope, key) = t("administrateurs.api_tokens.scopes.#{scope}.#{key}")
  end
end
