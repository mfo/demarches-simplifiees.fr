# frozen_string_literal: true

# Named places in the shared views where an optional feature contributes a
# partial, so those views never have to name the features themselves.
#
# Same contract as NavBarProfile: the host declares the point, the feature
# supplies the partial, and a point whose feature is off renders nothing.
module ViewExtensionHelper
  EXTENSIONS = {
    administrateur_main_navigation: [
      { partial: 'admins_group/administrateur_main_navigation', enabled: -> { Rails.application.config.ds_admins_group_enabled } },
    ],
    manager_user_meta: [
      { partial: 'admins_group/manager_user_meta', enabled: -> { Rails.application.config.ds_admins_group_enabled } },
    ],
  }.freeze

  # Unknown points raise rather than render nothing: a typo in a shared view
  # would otherwise silently drop whatever the feature meant to show there.
  def render_view_extensions(point, **locals)
    partials = EXTENSIONS.fetch(point).filter { it[:enabled].call }.map { it[:partial] }

    safe_join(partials.map { render(partial: it, locals:) })
  end
end
