# frozen_string_literal: true

class Champs::EtudiantBoursierChamp < Champs::FranceConnectChamp
  private

  def extract_value_json(data:)
    if (identite = data[:identite])
      extracted_identite = identite.merge(
        prenoms: identite[:prenoms]&.join(' ')
      )

      data.merge(identite: extracted_identite)
    else
      data
    end
  end
end
