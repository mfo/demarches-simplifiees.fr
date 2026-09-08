# frozen_string_literal: true

# Drawn into the host route set rather than mounted: the engine is not isolated,
# so its paths and helpers keep the names they had in the monolith.
if Rails.application.config.ds_admins_group_enabled
  Rails.application.routes.draw do
    scope module: 'gestionnaires', as: 'gestionnaire', defaults: { nav_bar_profile: :gestionnaire } do
      resources :groupe_gestionnaires, path: 'groupes', only: [:index, :show, :edit, :update, :destroy] do
        resources :gestionnaires, controller: 'groupe_gestionnaire_gestionnaires', only: [:index, :create, :destroy]
        resources :administrateurs, controller: 'groupe_gestionnaire_administrateurs', only: [:index, :create, :destroy] do
          delete :remove, on: :member
        end
        resources :children, controller: 'groupe_gestionnaire_children', only: [:index, :create]
        resources :commentaires, controller: 'groupe_gestionnaire_commentaires', only: [:index, :show, :create, :destroy] do
          collection do
            get 'parent_groupe_gestionnaire'
            post 'create_parent_groupe_gestionnaire'
          end
        end
        member do
          get :tree_structure, path: 'arborescence'
        end
      end
    end

    namespace :gestionnaires, defaults: { nav_bar_profile: :gestionnaire } do
      get 'activate' => '/users/activate#new'
      patch 'activate' => '/users/activate#create'
    end
  end
end
