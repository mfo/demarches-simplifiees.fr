# frozen_string_literal: true

class Champs::QuotientFamilialChamp < Champs::FranceConnectChamp
  private

  def extract_value_json(data:)
    if (qf_data = data[:quotient_familial])
      extract_qf_data = {
        fournisseur: qf_data[:fournisseur],
        valeur: qf_data[:valeur],
        periode_effective: Date.new(qf_data[:annee], qf_data[:mois]).iso8601,
        periode_calcul: Date.new(qf_data[:annee_calcul], qf_data[:mois_calcul]).iso8601,
      }

      data.merge(quotient_familial: extract_qf_data)
    else
      data
    end
  end
end
