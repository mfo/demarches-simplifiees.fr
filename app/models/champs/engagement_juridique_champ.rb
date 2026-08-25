# frozen_string_literal: true

class Champs::EngagementJuridiqueChamp < ChampData
  # cf: https://communaute.chorus-pro.gouv.fr/documentation/creer-un-engagement/#1522314752186-a34f3662-0644b5d1-16c22add-8ea097de-3a0a
  validates :value,
            format: {
              with: /\A[A-Z0-9_+\/-]+\z/,
              message: "Le numéro d'EJ ne peut contenir que des caractères alphanumérique et les caractères spéciaux suivant : “-“ ; “_“ ; “+“ ; “/“",
            },
            allow_blank: true,
            if: :should_validate_in_current_context?
end
