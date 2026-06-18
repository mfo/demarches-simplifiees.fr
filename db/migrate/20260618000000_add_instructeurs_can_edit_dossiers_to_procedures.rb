# frozen_string_literal: true

class AddInstructeursCanEditDossiersToProcedures < ActiveRecord::Migration[7.2]
  def change
    add_column :procedures, :instructeurs_can_edit_dossiers, :boolean, default: false, null: false
  end
end
