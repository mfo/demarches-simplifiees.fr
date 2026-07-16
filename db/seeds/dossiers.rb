# frozen_string_literal: true

procedure = procedures.individual

labels = %w[brouillon en_construction en_instruction accepte refuse].to_h do |state|
  dossier = Dossier.create!(
    user: users.usager,
    revision: procedure.active_revision,
    groupe_instructeur: procedure.defaut_groupe_instructeur,
    individual: Individual.new,
    autorisation_donnees: true
  )
  dossier.build_default_values

  if state != Dossier.states.fetch(:brouillon)
    dossier.state = state
    processed_at = DossierWithReferenceDate.assign(dossier)

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

  [state.to_sym, dossier]
end

dossiers.label(**labels)
