# frozen_string_literal: true

module FranceConnectChamp
  class AEEHRowsBuilder < BaseRowsBuilder
    def build(data)
      rows = []

      statut = data["status"]
      date_debut_droit = data["date_debut_droit"]

      if statut.present?
        rows << ["Statut", human_status(statut)]
      end

      if date_debut_droit.present?
        rows << ["Date de début de droit", I18n.l(Date.parse(date_debut_droit), format: :short)]
      end

      rows
    end

    private

    def human_status(statut)
      case statut
      when "allocataire"
        "Allocataire de l'AEEH"
      when "ouvrant_droit"
        "Ouvrant droit de l'AEEH"
      when "non_beneficiaire"
        "Non bénéficiaire de l'AEEH"
      else
        statut.to_s.humanize
      end
    end
  end
end
