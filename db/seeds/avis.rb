# frozen_string_literal: true

# An expert invited on the individual procedure, with a pending avis requested by the
# default instructeur on the en_instruction dossier and an answered avis on the
# accepte dossier.

expert_user = users.create :expert, email: "expert@exemple.fr"
expert_user.create_expert!
experts.label default: expert_user.expert

experts_procedure = experts_procedures.create(expert: experts.default, procedure: procedures.individual)
experts_procedures.label default: experts_procedure

pending_avis = avis.create(
  dossier: dossiers.en_instruction,
  claimant: instructeurs.default,
  experts_procedure:,
  confidentiel: false,
  introduction: "Bonjour, merci de me donner votre avis sur ce dossier."
)
avis.label pending: pending_avis

answered_avis = avis.create(
  dossier: dossiers.accepte,
  claimant: instructeurs.default,
  experts_procedure:,
  confidentiel: false,
  introduction: "Bonjour, merci de me donner votre avis sur ce dossier.",
  answer: "La demande semble pertinente et le demandeur remplit les conditions."
)
avis.label answered: answered_avis
