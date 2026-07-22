# frozen_string_literal: true

# The GraphQL API v2 dossiers connections keyset-paginate over
# (depose_at, id) — or (updated_at, id) when `updatedSince` is given — always
# scoped to `visible_by_administration` (hidden_by_administration_at IS NULL AND
# hidden_by_expired_at IS NULL). The connection is reached two ways, each
# filtering on a different tenant column:
#   - demarche.dossiers      -> joins procedure_revisions, filters revision_id
#   - groupeInstructeur.dossiers -> filters groupe_instructeur_id
#
# Without these indexes every page does a filtered sort over the heap. EXPLAIN
# confirms the plain (depose_at/updated_at, id) index lets the demarche join walk
# in order and stop at the LIMIT, and the (groupe_instructeur_id, ...) composite
# gives the groupe path a sort-free Index Scan.
#
# Partial on the visible_by_administration predicate, matching
# index_dossiers_on_groupe_instructeur_id_and_state_and_archived.
class AddDossiersConnectionOrderingIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  VISIBLE_BY_ADMINISTRATION = "hidden_by_administration_at IS NULL AND hidden_by_expired_at IS NULL"

  def change
    add_index :dossiers, [:depose_at, :id],
              where: VISIBLE_BY_ADMINISTRATION,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :dossiers, [:updated_at, :id],
              where: VISIBLE_BY_ADMINISTRATION,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :dossiers, [:groupe_instructeur_id, :depose_at, :id],
              where: VISIBLE_BY_ADMINISTRATION,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :dossiers, [:groupe_instructeur_id, :updated_at, :id],
              where: VISIBLE_BY_ADMINISTRATION,
              algorithm: :concurrently,
              if_not_exists: true
  end
end
