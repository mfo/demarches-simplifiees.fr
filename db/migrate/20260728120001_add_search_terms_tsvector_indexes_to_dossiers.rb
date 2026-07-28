# frozen_string_literal: true

# GIN indexes on the stored tsvector columns added by
# AddSearchTermsTsvectorToDossiers.
#
# These replace index_dossiers_on_search_terms and
# index_dossiers_on_search_terms_private_search_terms, which stay in place until
# the backfill has completed and the :search_terms_tsvector flag has been on long
# enough to be trusted — dropping them is a follow-up.
class AddSearchTermsTsvectorIndexesToDossiers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :dossiers, :search_terms_tsvector,
              using: :gin,
              name: :index_dossiers_on_search_terms_tsvector,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :dossiers, :all_search_terms_tsvector,
              using: :gin,
              name: :index_dossiers_on_all_search_terms_tsvector,
              algorithm: :concurrently,
              if_not_exists: true
  end
end
