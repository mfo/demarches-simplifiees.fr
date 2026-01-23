# frozen_string_literal: true

module Instructeurs
  class ChampsController < InstructeurController
    before_action :set_dossier
    before_action :set_dossier_stream
    before_action :set_champ, only: [:edit]

    def edit; end

    private

    def set_dossier
      @dossier = DossierPreloader.load_one(
        current_instructeur.dossiers.visible_by_administration.find(params[:dossier_id])
      )
    end

    def set_dossier_stream
      @dossier.with_instructeur_buffer_stream
    end

    def set_champ
      stable_id, row_id = params[:public_id].split("-")
      type_de_champ = @dossier.find_type_de_champ_by_stable_id(stable_id)
      @champ = @dossier.project_champ(type_de_champ, row_id:)
    end
  end
end
