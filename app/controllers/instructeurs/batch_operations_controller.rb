module Instructeurs
  class BatchOperationsController < ApplicationController
    before_action :ensure_ownership!

    def create
      ActiveRecord::Base.transaction do
        batch_operation = BatchOperation.create!(batch_operation_params.merge(instructeur: current_instructeur))
        BatchOperationEnqueueAllJob.perform_later(batch_operation)
      end
      redirect_back(fallback_location: instructeur_procedure_url(procedure.id))
    end

    private

    def batch_operation_params
      params.require(:batch_operation)
        .permit(:operation, dossier_ids: []).tap do |params|
              # TODO: filter dossiers_ids out of instructeurs.dossiers.ids
            end
    end

    def procedure_id
      params[:procedure_id]
    end

    def procedure
      Procedure.find(procedure_id)
    end

    def ensure_ownership!
      if !current_instructeur.procedures.include?(procedure)
        flash[:alert] = "Vous n’avez pas accès à cette démarche"
        redirect_to root_path
      end
    end
  end
end
