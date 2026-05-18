# frozen_string_literal: true

class RemoveAPIParticulierColumnsFromProcedures < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      remove_index :procedures, name: :index_procedures_on_api_particulier_sources

      remove_column :procedures, :api_particulier_scopes
      remove_column :procedures, :api_particulier_sources
      remove_column :procedures, :encrypted_api_particulier_token
    end
  end

  def down
    add_column :procedures, :api_particulier_scopes, :text, array: true, default: []
    add_column :procedures, :api_particulier_sources, :jsonb, default: {}
    add_column :procedures, :encrypted_api_particulier_token, :string

    add_index :procedures,
              :api_particulier_sources,
              using: :gin,
              name: :index_procedures_on_api_particulier_sources
  end
end
