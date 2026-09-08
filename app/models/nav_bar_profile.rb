# frozen_string_literal: true

# The profiles a signed-in account can hold, ordered from the most specific to
# the least: the first one an account holds is the profile it lands on.
#
# Shared chrome — the account dropdown, the nav bar, the breadcrumbs, the
# request logs — iterates this list instead of carrying one branch per profile.
# A profile that ships only to some instances declares its condition in
# OPTIONAL; when the condition is false, the profile does not exist at all.
module NavBarProfile
  ALL = [:gestionnaire, :administrateur, :instructeur, :expert, :user].freeze

  OPTIONAL = {
    gestionnaire: -> { Rails.application.config.ds_admins_group_enabled },
  }.freeze

  def self.all
    ALL.filter { OPTIONAL.key?(it) ? OPTIONAL[it].call : true }
  end

  # Every profile but :user, which every signed-in account holds by definition.
  def self.roles
    all.excluding(:user)
  end
end
