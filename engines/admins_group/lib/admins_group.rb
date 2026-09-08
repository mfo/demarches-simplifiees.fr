# frozen_string_literal: true

require 'ancestry'
require 'admins_group/engine'

# Named after ADMINS_GROUP_ENABLED rather than after the domain: Gestionnaire
# and GroupeGestionnaire are ActiveRecord classes of the host, and a module of
# the same name would shadow them.
module AdminsGroup
end
