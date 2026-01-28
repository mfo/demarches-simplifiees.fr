# frozen_string_literal: true

module ApplicationController::MigrateCsrfToken
  extend ActiveSupport::Concern

  included do
    before_action :migrate_legacy_csrf_token

    # Migrate le token de notre ancien cookie vers le nouveau standard
    # pour que les utilisateurs puissent continuer de soumettre un formulaire pendant le déploiement de rails 7.1
    def migrate_legacy_csrf_token
      # Ne migre que si le nouveau cookie n’existe pas déjà
      # Gère le cas où le cookie pourrait contenir des séquences UTF-8 invalides
      begin
        return if cookies[:csrf_token].present?
      rescue ArgumentError
        # Si le cookie contient des données invalides, on le considère comme absent
        # et on procède à la migration
      end

      legacy_token = cookies.signed[:_csrf_token]
      return if legacy_token.blank?

      # Réutilise l’ancien token dans le nouveau format Rails 7.1
      self.csrf_token_storage_strategy.store(request, legacy_token)
    end
  end
end
