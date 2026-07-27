# frozen_string_literal: true

devise_for :super_admins, skip: [:registrations], controllers: {
  sessions: 'super_admins/sessions',
}

namespace :super_admins, defaults: { nav_bar_profile: :superadmin } do
  resources :release_notes
end

get 'super_admins/edit_otp', to: 'super_admins#edit_otp', as: 'edit_super_admin_otp', defaults: { nav_bar_profile: :superadmin }
put 'super_admins/enable_otp', to: 'super_admins#enable_otp', as: 'enable_super_admin_otp', defaults: { nav_bar_profile: :superadmin }
