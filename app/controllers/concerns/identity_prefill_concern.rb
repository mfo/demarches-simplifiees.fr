# frozen_string_literal: true

# Fabrique la source de préremplissage de l'identité pour la requête courante,
# pour les contrôleurs et les vues qui rendent l'étape identité.
module IdentityPrefillConcern
  extend ActiveSupport::Concern

  included do
    helper_method :identity_prefill_source
  end

  def identity_prefill_source(dossier)
    IdentityPrefillSource.new(dossier:)
  end
end
