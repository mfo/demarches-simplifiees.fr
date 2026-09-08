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
  # Its tables are part of the host schema, so db/migrate and db/schema.rb stay
  # in the host: a disabled instance still carries the columns, it just never
  # reaches the feature.
  class Engine < ::Rails::Engine
    # The engine's specs live next to its code, so the mailer previews have to be
    # told where to look. Its factories are picked up by rails_helper's glob.
    initializer 'admins_group.mailer_previews' do |app|
      app.config.action_mailer.preview_paths << root.join('spec/mailers/previews').to_s
    end
  end
end
