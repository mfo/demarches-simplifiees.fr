# frozen_string_literal: true

class AddChampsStableIdAndDossierIdIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # The single-column stable_id index is a planner trap: dossier-scoped champ
    # lookups (create_or_find_by conflict SELECT, clone-from-main find_by) all
    # estimate ~1 row, and on that tie the planner picks the smallest index —
    # scanning every champ of a popular stable_id across all dossiers. Adding
    # dossier_id keeps the tie-break winner scoped to the dossier.
    add_index :champs, [:stable_id, :dossier_id], algorithm: :concurrently, name: 'index_champs_on_stable_id_and_dossier_id'
  end
end
