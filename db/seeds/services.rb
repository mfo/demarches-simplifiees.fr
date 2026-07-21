# frozen_string_literal: true

# A published procedure without a service is nagged about on every admin page,
# so every seeded procedure gets this default service.
services.create :default,
  nom: "Service de démonstration",
  administrateur: administrateurs.default,
  organisme: "Organisme de démonstration",
  type_organisme: Service.type_organismes.fetch(:administration_centrale),
  email: "contact@exemple.fr",
  telephone: "0102030405",
  horaires: "Du lundi au vendredi, de 9 h à 18 h",
  adresse: "20 avenue de Ségur, 75007 Paris",
  siret: "13002526500013"
