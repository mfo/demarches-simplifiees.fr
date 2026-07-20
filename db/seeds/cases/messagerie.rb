# frozen_string_literal: true

# A message sent by the default instructeur on the en_construction dossier.
# Load in a spec with `seed "cases/messagerie"`.

message = commentaires.create(
  dossier: dossiers.en_construction,
  instructeur: instructeurs.default,
  email: users.instructeur.email,
  body: "Bonjour, pouvez-vous préciser la date de début de votre projet ?"
)
commentaires.label from_instructeur: message
