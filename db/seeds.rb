# frozen_string_literal: true

# Seed data is managed with Oaken (https://github.com/kaspth/oaken) and shared
# between development and test:
#
# - db/seeds/setup.rb        — helpers and defaults (loaded automatically)
# - db/seeds/users.rb        — usager / administrateur / instructeur personas
# - db/seeds/procedures.rb   — a published demo procedure with common types de champ
# - db/seeds/dossiers.rb     — dossiers in various states on the individual procedure
# - db/seeds/development/    — development-only records (super-admin, fixer instructeur)
# - db/seeds/cases/          — scenario-specific data (expert avis, messagerie, …)
#
# In specs, tag an example group with :oaken to load these seeds and access the
# labeled records (users.usager, procedures.individual, dossiers.en_construction, …).
# Scenario seeds are loaded per spec with e.g. `before { seed "cases/avis" }`.
#
# Seeds assume an empty database and are not re-runnable: specs load them in
# rolled-back transactions, and a development database is refreshed with
# `bin/rails db:seed:replant` (truncate + reseed).
Oaken.seed :users, :procedures, :dossiers
Oaken.seed :cases if Rails.env.development?
