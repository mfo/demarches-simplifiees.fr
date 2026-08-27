# frozen_string_literal: true

class DropProcedureExpiresWhenTermineEnabledFromProcedures < ActiveRecord::Migration[8.0]
  def change
    # Colonne ignorée via `ignored_columns` depuis la PR #13341, déployée le
    # 2026-06-26 : plus aucun process ne la référence, le drop est sans impact.
    safety_assured do
      remove_column :procedures, :procedure_expires_when_termine_enabled, :boolean, default: true
    end
  end
end
