# frozen_string_literal: true

class AddScopesToAPITokens < ActiveRecord::Migration[8.1]
  def change
    add_column :api_tokens, :scopes, :string, array: true
  end
end
