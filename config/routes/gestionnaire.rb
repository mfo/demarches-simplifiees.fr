# frozen_string_literal: true

if ENV['ADMINS_GROUP_ENABLED'] == 'enabled' || Rails.env.test? # can be removed if needed when EVERY PARTS of the feature will be merged / from env.example.optional
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
