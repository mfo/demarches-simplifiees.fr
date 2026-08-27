# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

# Routes are organized by profile in config/routes/*.rb.
# For details on the DSL available within those files, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  draw :manager
  draw :superadmin
  draw :authentication
  draw :misc
  draw :shared
  draw :api
  draw :usager
  draw :expert
  draw :instructeur
  draw :gestionnaire
  draw :administrateur
end
