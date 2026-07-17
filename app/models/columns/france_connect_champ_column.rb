# frozen_string_literal: true

class Columns::FranceConnectChampColumn < Columns::JSONPathColumn
  QUOTIENT_FAMILIAL_COLUMNS = [
    ['[Allocataire 1] Nom de naissance', '$.api_part.allocataires[0].nom_naissance', :text],
    ['[Allocataire 1] Prénoms', '$.api_part.allocataires[0].prenoms', :text],
    ['[Allocataire 2] Nom de naissance', '$.api_part.allocataires[1].nom_naissance', :text],
    ['[Allocataire 2] Prénoms', '$.api_part.allocataires[1].prenoms', :text],
    ['Valeur du QF', '$.api_part.quotient_familial.valeur', :integer],
    ['Période du QF', '$.api_part.quotient_familial.periode_effective', :date],
  ]

  ETUDIANT_BOURSIER_COLUMNS = [
    ['Boursier', '$.api_part.statut_boursier.est_boursier', :boolean],
    ['Radié', '$.api_part.statut_boursier.est_radie', :boolean],
    ['Début de versement', '$.api_part.periode_versement_bourse.date_rentree', :date],
    ['Nombre de mois de versement', '$.api_part.periode_versement_bourse.duree', :integer],
    ["Commune d'études", '$.api_part.etablissement_etudes.nom_commune', :text],
    ["Nom de l'établissement", '$.api_part.etablissement_etudes.nom_etablissement', :text],
    ['Echelon de la bourse', '$.api_part.echelon_bourse.echelon', :text],
    ['Nom', '$.api_part.identite.nom', :text],
    ['Prénoms', '$.api_part.identite.prenoms', :text],
  ]

  AAH_COLUMNS = [
    ['Bénéficiaire de l’AAH', '$.api_part.est_beneficiaire', :boolean],
    ['Date de début de droit', '$.api_part.date_debut_droit', :date],
  ]

  AEEH_COLUMNS = [
    ['Statut', '$.api_part.status', :text],
    ['Date de début de droit', '$.api_part.date_debut_droit', :date],
  ]

  def targeted_dossiers(dossiers, condition)
    super(dossiers, condition).where(champs: { value: 'true' })
  end

  private

  def typed_value(champ)
    return super if champ.fc_data_correct?
  end
end
