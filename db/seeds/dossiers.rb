# frozen_string_literal: true

procedure = procedures.individual

%w[brouillon en_construction en_instruction accepte refuse].each do |state|
  dossier = dossiers.create(
    state.to_sym,
    user: users.usager,
    revision: procedure.active_revision,
    groupe_instructeur: procedure.defaut_groupe_instructeur,
    individual: Individual.new(gender: "Mme", nom: "Dupont", prenom: "Jeanne", birthdate: Date.new(1985, 3, 12)),
    autorisation_donnees: true
  )
  dossier.build_default_values

  if state != Dossier.states.fetch(:brouillon)
    dossier.state = state
    # Deposited dossiers are backdated so that specs freezing time to earlier
    # today still see the seeded traitements in the past.
    processed_at = DossierWithReferenceDate.assign(dossier, reference_date: 1.day.ago)

    case state
    when Dossier.states.fetch(:en_construction)
      dossier.traitements.passer_en_construction(processed_at:)
    when Dossier.states.fetch(:en_instruction)
      dossier.traitements.passer_en_instruction(processed_at:)
    when Dossier.states.fetch(:accepte)
      dossier.traitements.accepter(motivation: "Dossier complet.", processed_at:)
    when Dossier.states.fetch(:refuse)
      dossier.traitements.refuser(motivation: "Dossier incomplet.", processed_at:)
    end

    dossier.submitted_revision_id = dossier.revision_id
    dossier.save!
  end
end
