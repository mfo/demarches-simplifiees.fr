# frozen_string_literal: true

module FranceConnectChamp
  class AahRowsBuilder < BaseRowsBuilder
    def build(data)
      rows = []

      beneficiaire = data["est_beneficiaire"]
      date_debut_droit = data["date_debut_droit"]

      if beneficiaire.present?
        rows << ["Bénéficiaire de l’AAH", beneficiaire ? 'Oui' : 'Non']
      end

      if date_debut_droit.present?
        rows << ["Date de début de droit", I18n.l(Date.parse(date_debut_droit), format: :short)]
      end

      rows
    end
  end
end
