# frozen_string_literal: true

# Résout la source de préremplissage de l'identité d'un dossier (nom, prénom,
# civilité) à partir du fournisseur d'identité de l'usager.
#
# Consommé par le composant du formulaire identité, les contrôleurs et
# DossierFranceConnectPrefillConcern, qui s'accordent ainsi par construction
# plutôt que par ordre d'exécution.
class IdentityPrefillSource
  attr_reader :dossier

  def initialize(dossier:)
    @dossier = dossier
  end

  # :france_connect | nil — FranceConnect se résout depuis l'identité persistée
  # de l'usager, pas depuis la session.
  def resolved
    return @resolved if defined?(@resolved)

    @resolved = (:france_connect if dossier.identity_from_fc?)
  end

  def none? = resolved.nil?
  def france_connect? = resolved == :france_connect

  # Champs de `individual` à verrouiller ET à stripper côté serveur.
  #
  # Retourne [] quand for_tiers? : c'est ce qui rend `individual_locked_fields`
  # et `mandataire_locked?` mutuellement exclusifs (le contrôleur peut alors
  # traiter les deux dans des `if` indépendants plutôt qu'en if/elsif ordonné).
  def individual_locked_fields
    return [] if dossier.for_tiers? || none?

    [:nom, :prenom, :gender]
  end

  def individual_field_locked?(field) = individual_locked_fields.include?(field)

  def mandataire_locked? = dossier.for_tiers? && !none?

  def france_connect_information = dossier.user&.france_connect_informations&.first
end
