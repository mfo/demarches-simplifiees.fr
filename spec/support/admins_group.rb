# frozen_string_literal: true

# The "groupe gestionnaire" feature only ships to the instances that enable it
# (config.ds_admins_group_enabled). Its specs need the routes and the profile
# that only exist when the app booted with it on, so tag them :admins_group —
# the CI job that runs the suite with the feature off skips them.
#
# Every spec of the engine — and any leftover spec named after the feature — is
# tagged automatically; examples about the feature that live in a shared spec of
# the host must carry the tag themselves.
RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{engines/admins_group/spec|gestionnaire}) do |metadata|
    metadata[:admins_group] = true
  end
end
