# frozen_string_literal: true

# Stored tsvector columns for the instructeur/expert full-text search.
#
# The search filters and ranks on expression indexes over
# `to_tsvector('french_unaccent', search_terms [|| private_search_terms])`. The
# GIN indexes serve the `@@` filter, but `ts_rank` cannot use them: it recomputes
# the tsvector for every candidate row, so ranking a large match set times out
# (RAILS-K81). Capping the match set before ranking only moved the timeout into
# the capped query itself (RAILS-MC2). Storing the tsvector lets ranking read a
# precomputed value instead.
#
# Two columns, mirroring the two existing expression indexes rather than
# splitting public/private: `to_tsquery` builds an AND of prefixes, so a query
# whose terms span the public and private parts matches the concatenation but
# neither part alone. `all_search_terms_tsvector` keeps that behaviour.
#
# Nullable, and deliberately not GENERATED ... STORED: a generated column would
# rewrite this very large table under an ACCESS EXCLUSIVE lock. Maintained going
# forward by DossierSearchableConcern#index_search_terms and backfilled by
# Maintenance::T20260728BackfillSearchTermsTsvectorTask.
class AddSearchTermsTsvectorToDossiers < ActiveRecord::Migration[8.0]
  def change
    add_column :dossiers, :search_terms_tsvector, :tsvector
    add_column :dossiers, :all_search_terms_tsvector, :tsvector
  end
end
