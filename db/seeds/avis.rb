# frozen_string_literal: true

# Two experts invited on the individual procedure. The default expert has a
# pending avis requested by the default instructeur on the en_instruction
# dossier, an answered avis on the accepte dossier and an answered avis with an
# attached introduction file, also on the accepte dossier. The second expert
# has a confidentiel avis on the en_instruction dossier — visible to itself but
# not to the default expert.

expert_user = users.create :expert, email: "expert@exemple.fr"
expert_user.create_expert!
experts.label default: expert_user.expert

second_expert_user = users.create :second_expert, email: "expert2@exemple.fr"
second_expert_user.create_expert!
experts.label second: second_expert_user.expert

experts_procedure = experts_procedures.create :default, expert: experts.default, procedure: procedures.individual
second_experts_procedure = experts_procedures.create :second, expert: experts.second, procedure: procedures.individual

avis.create :pending,
  dossier: dossiers.en_instruction,
  claimant: instructeurs.default,
  experts_procedure:,
  confidentiel: false,
  introduction: "Bonjour, merci de me donner votre avis sur ce dossier."

avis.create :answered,
  dossier: dossiers.accepte,
  claimant: instructeurs.default,
  experts_procedure:,
  confidentiel: false,
  introduction: "Bonjour, merci de me donner votre avis sur ce dossier.",
  answer: "La demande semble pertinente et le demandeur remplit les conditions."

avis.create :confidentiel,
  dossier: dossiers.en_instruction,
  claimant: instructeurs.default,
  experts_procedure: second_experts_procedure,
  confidentiel: true,
  introduction: "Bonjour, merci de me donner votre avis confidentiel sur ce dossier."

with_file_avis = avis.create :with_file,
  dossier: dossiers.accepte,
  claimant: instructeurs.default,
  experts_procedure:,
  confidentiel: false,
  introduction: "Bonjour, vous trouverez le contexte dans le fichier joint.",
  answer: "Avis favorable, au vu du document joint."
white_pixel_png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")
with_file_avis.introduction_file.attach(
  io: StringIO.new(white_pixel_png),
  filename: "introduction.png",
  content_type: "image/png",
  metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
)
