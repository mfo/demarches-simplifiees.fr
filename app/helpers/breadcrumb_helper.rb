# frozen_string_literal: true

module BreadcrumbHelper
  def breadcrumb_root_for(profile)
    key = NavBarProfile.all.include?(profile) ? profile : :default

    [t("layouts.breadcrumb.root.#{key}"), profile_home_path(profile)]
  end
end
