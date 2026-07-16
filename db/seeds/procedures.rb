# frozen_string_literal: true

procedure = Procedure.new(
  libelle: "Démarche de démonstration",
  description: "Une démarche de démonstration avec les types de champ les plus courants.",
  cadre_juridique: "https://www.legifrance.gouv.fr/",
  lien_site_web: "https://www.exemple.fr",
  duree_conservation_dossiers_dans_ds: 3,
  max_duree_conservation_dossiers_dans_ds: Procedure::OLD_MAX_DUREE_CONSERVATION,
  for_individual: true,
  administrateurs: [administrateurs.default]
)
procedure.draft_revision = procedure.revisions.build
procedure.save!

[
  { type_champ: "text", libelle: "Nom du projet", mandatory: true },
  { type_champ: "textarea", libelle: "Description du projet", mandatory: true },
  { type_champ: "date", libelle: "Date de début" },
  { type_champ: "drop_down_list", libelle: "Type de projet", drop_down_options: ["Association", "Entreprise", "Collectivité"] },
  { type_champ: "checkbox", libelle: "Le projet bénéficie d'un financement public" },
  { type_champ: "piece_justificative", libelle: "Justificatif" },
].reduce(nil) do |previous, params|
  type_de_champ = procedure.draft_revision.add_type_de_champ(**params, after_stable_id: previous&.stable_id)
  raise type_de_champ.errors.full_messages.to_sentence if type_de_champ.errors.any?
  type_de_champ
end

procedure.publish_or_reopen!(administrateurs.default, "demarche-demo")
instructeurs.default.assign_to_procedure(procedure)

procedures.label individual: procedure
