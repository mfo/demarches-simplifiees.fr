# frozen_string_literal: true

class CreateDossiersListPersonnalisations < ActiveRecord::Migration[7.2]
  def change
    create_table :dossiers_list_personnalisations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :procedure, null: false, foreign_key: true
      t.jsonb :displayed_columns, null: false, default: [], array: true
      t.timestamps

      t.index [:user_id, :procedure_id], unique: true
    end
  end
end
