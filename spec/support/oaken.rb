# frozen_string_literal: true

# Oaken seeds (db/seeds/) are opt-in: tag an example group with :oaken to load
# the shared seed data inside the example's transaction and access the labeled
# records (users.usager, procedures.individual, dossiers.en_construction, …).
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

RSpec.configure do |config|
  config.include Oaken.loader.context, :oaken
  config.prepend OakenSupport, :oaken
  config.prepend_before(:each, :oaken) { Oaken.loader.seed :users, :procedures, :dossiers }
end
