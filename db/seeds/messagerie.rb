# frozen_string_literal: true

# A message sent by the default instructeur on the en_construction dossier,
# and the usager's reply.

message = commentaires.create(
  dossier: dossiers.en_construction,
  instructeur: instructeurs.default,
  email: users.instructeur.email,
  body: "Bonjour, pouvez-vous préciser la date de début de votre projet ?"
)
commentaires.label from_instructeur: message

reply = commentaires.create(
  dossier: dossiers.en_construction,
  email: users.usager.email,
  body: "Bonjour, le projet commencera au début du mois de septembre."
)
commentaires.label from_usager: reply
