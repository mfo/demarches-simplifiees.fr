# frozen_string_literal: true

class Migrations::BackfillDossierRepetitionJob < ApplicationJob
  def perform(dossier_ids)
    Dossier.where(id: dossier_ids)
      .includes(:champ_data, revision: :type_de_champs)
      .find_each do |dossier|
        dossier
          .revision
          .type_de_champs
          .filter do |type_de_champ|
            type_de_champ.type_champ == 'repetition' && dossier.champ_data.none? { _1.stable_id == type_de_champ.stable_id }
          end
          .each do |type_de_champ|
            dossier.champ_data << type_de_champ.build_champ
          end
      end
  end
end
