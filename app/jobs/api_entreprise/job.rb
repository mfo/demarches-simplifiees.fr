# frozen_string_literal: true

class APIEntreprise::Job < ApplicationJob
  queue_as :default

  use_sidekiq_retry

  # If by the time the job runs the Etablissement has been deleted
  # (it can happen through EtablissementUpdateJob for instance), ignore the job
  discard_on ActiveRecord::RecordNotFound

  def log_job_exception(exception)
    if etablissement.present?
      if etablissement.dossier.present?
        etablissement.dossier.log_api_entreprise_job_exception(exception)
      elsif etablissement.champ.present?
        etablissement.champ.save_additional_job_exception(exception, :unkonwn)
      end
    end
  end

  attr_reader :etablissement

  def find_etablissement(etablissement_id)
    @etablissement = Etablissement.find(etablissement_id)
  end
end
