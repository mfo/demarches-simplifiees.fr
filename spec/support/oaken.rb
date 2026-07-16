# frozen_string_literal: true

require 'test_prof/recipes/rspec/before_all'

# Oaken seeds (db/seeds/) are opt-in: tag an example group with :oaken to load
# the shared seed data once per group (via test-prof's before_all transaction)
# and access the labeled records (users.usager, procedures.individual,
# dossiers.en_construction, …). Scenario seeds (db/seeds/cases/) load with
# `before_all { seed "cases/avis" }`; per-example mutations of seeded records
# roll back to the group snapshot after each example.
module OakenSupport
  # The global fixtures (config.global_fixtures) define `users`, `instructeurs`
  # and `administrateurs` accessors directly on each example group, shadowing
  # Oaken's. Prepend to route no-arg calls to Oaken; calls with fixture names
  # (e.g. `users(:default_user)`) still reach the fixture accessor via super.
  [:users, :instructeurs, :administrateurs].each do |name|
    define_method(name) do |*fixture_names|
      fixture_names.empty? ? Oaken::Seeds.public_send(name) : super(*fixture_names)
    end
  end
end

RSpec.shared_context 'with oaken seeds' do
  before_all { Oaken.loader.seed :users, :procedures, :dossiers }
end

RSpec.configure do |config|
  config.include Oaken.loader.context, :oaken
  config.prepend OakenSupport, :oaken
  config.include_context 'with oaken seeds', :oaken
end

# Specs asserting on global aggregates or unparameterized scopes (raw SQL over
# a whole table, `Dossier.some_scope`, `Procedure.all`) can't scope their
# queries to spec-created records. Declare the models whose tables must start
# empty at the top of the group, before any `let_it_be`:
#
#   describe '.dossiers_states' do
#     empty_seeds Dossier
#
# All rows of the given models are destroyed once per group, inside the
# group's before_all transaction: examples start from an empty table and the
# seeded world comes back when the group's transaction rolls back. List
# dependents before their parents (e.g. `empty_seeds Dossier, Procedure` —
# procedures restrict deletion while dossiers exist). Seed accessors for the
# wiped models (dossiers.en_construction, …) must not be used in the group.
module EmptySeeds
  def empty_seeds(*models)
    # unscoped: the wipe must also remove rows hidden by default scopes (discarded procedures)
    before_all { models.each { it.unscoped.destroy_all } } # rubocop:disable DS/Unscoped
  end
end

RSpec.configure do |config|
  config.extend EmptySeeds
end
