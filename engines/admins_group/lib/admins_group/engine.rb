# frozen_string_literal: true

module AdminsGroup
  # The "groupe gestionnaire" feature, shipped only to the instances that turn
  # it on (ADMINS_GROUP_ENABLED, read into config.ds_admins_group_enabled).
  #
  # The engine is deliberately NOT isolated: its models, controllers and routes
  # live in the host's namespaces, next to the other profiles they extend
  # (User, Administrateur, ApplicationController). Isolating it would rename
  # every route helper for no benefit.
  #
  # db/schema.rb stays in the host: it is dumped from the whole database, which
  # holds the feature's tables like any other.
  class Engine < ::Rails::Engine
    # The engine owns the tables of the feature, so it carries their migrations.
    # Appending the path, rather than installing copies into the host's
    # db/migrate, keeps them with the code they belong to. Already-applied
    # versions are tracked in schema_migrations, so moving the files changes
    # nothing for an existing database.
    initializer 'admins_group.migrations' do |app|
      config.paths['db/migrate'].expanded.each { app.config.paths['db/migrate'] << it }
    end

    # The engine's specs live next to its code, so the mailer previews have to
    # be told where to look. Its factories are picked up by rails_helper's glob.
    initializer 'admins_group.mailer_previews' do |app|
      app.config.action_mailer.preview_paths << root.join('spec/mailers/previews').to_s
    end
  end
end
