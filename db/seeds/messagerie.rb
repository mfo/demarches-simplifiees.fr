# frozen_string_literal: true

# A message sent by the default instructeur on the en_construction dossier,
# and the usager's reply.

commentaires.create :from_instructeur,
  dossier: dossiers.en_construction,
  instructeur: instructeurs.default,
  email: users.instructeur.email,
  body: "Bonjour, pouvez-vous préciser la date de début de votre projet ?"

commentaires.create :from_usager,
  dossier: dossiers.en_construction,
  email: users.usager.email,
  body: "Bonjour, le projet commencera au début du mois de septembre."
