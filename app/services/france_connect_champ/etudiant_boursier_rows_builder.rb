# frozen_string_literal: true

module FranceConnectChamp
  class EtudiantBoursierRowsBuilder < BaseRowsBuilder
    def build(data)
      rows = []

      statut = data["statut_boursier"]
      periode = data["periode_versement_bourse"]
      etablissement = data["etablissement_etudes"]
      echelon = data["echelon_bourse"]
      identite = data["identite"]
      email = data["email"]

      if statut.present?
        rows << ["Statut boursier", statut_values(statut)]
      end

      if periode.present?
        rows << ["Période de versement de la bourse", periode_values(periode)]
      end

      if etablissement.present?
        rows << ["Établissement d'études", etablissement_values(etablissement)]
      end

      if echelon.present?
        rows << ["Échelon de bourse", echelon_values(echelon)]
      end

      if identite.present?
        rows << ["Identité", individual_values(identite)]
      end

      if email.present?
        rows << ["Adresse électronique", email]
      end

      rows
    end

    private

    def statut_values(statut)
      {
        "Boursier" => statut["est_boursier"] ? "Oui" : "Non",
        "Radié" => statut["est_radie"] ? "Oui" : "Non",
        "Date de radiation" => format_date(statut["date_radiation"]),
      }.compact
    end

    def periode_values(periode)
      {
        "Date de rentrée" => format_date(periode["date_rentree"]),
        "Nombre de mois" => periode["duree"],
      }.compact
    end

    def etablissement_values(etablissement)
      {
        "Nom de l'établissement" => etablissement["nom_etablissement"],
        "Commune" => etablissement["nom_commune"],
      }.compact
    end

    def echelon_values(echelon)
      {
        "Échelon" => echelon["echelon"],
        "Bourse régionale provisoire" => echelon["echelon_bourse_regionale_provisoire"] ? "Oui" : "Non",
      }.compact
    end

    def individual_values(individual)
      {
        "Nom" => individual["nom"],
        "Prénoms" => Array(individual["prenoms"]).join(" "),
        "Date de naissance" => format_date(individual["date_naissance"]),
        "Commune de naissance" => individual["nom_commune_naissance"],
        "Sexe" => individual["sexe"],
      }.compact
    end

    def format_date(date_string)
      return nil if date_string.blank?
      I18n.l(Date.parse(date_string), format: :short)
    end
  end
end
