# frozen_string_literal: true

scope module: 'experts', as: 'expert', defaults: { nav_bar_profile: :expert } do
  get 'avis', to: 'avis#index', as: 'all_avis'

  resources :procedures, only: [], param: :procedure_id do
    member do
      get 'notification_settings', to: 'avis#notification_settings'
      patch 'update_notification_settings', to: 'avis#update_notification_settings'

      resources :avis, only: [:show, :update] do
        get '', action: 'procedure', on: :collection, as: :procedure
        member do
          get 'instruction'
          get 'avis_list'
          get 'avis_new'
          get 'messagerie'
          post 'commentaire' => 'avis#create_commentaire'
          post 'avis' => 'avis#create_avis'
          get 'bilans_bdf'
          get 'telecharger_pjs' => 'avis#telecharger_pjs'

          get 'sign_up' => 'avis#sign_up'
          post 'sign_up' => 'avis#update_expert'
        end
      end
    end
  end
end
