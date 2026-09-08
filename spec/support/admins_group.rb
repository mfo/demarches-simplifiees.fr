# frozen_string_literal: true

# The "groupe gestionnaire" feature only ships to the instances that enable it
# (config.ds_admins_group_enabled). Its specs need the routes and the profile
# that only exist when the app booted with it on, so tag them :admins_group —
# the CI job that runs the suite with the feature off skips them.
#
# Every spec living under a gestionnaire path is tagged automatically; examples
# about the feature that live in a shared spec must carry the tag themselves.
RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{gestionnaire}) do |metadata|
    metadata[:admins_group] = true
  end
end
