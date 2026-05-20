# frozen_string_literal: true

class Cron::DiscardedDossiersDeletionBaseJob < Cron::CronJob
  MAX_DOSSIERS_PER_RUN = 100

  # Classe abstraite : empêche `rake jobs:schedule` de tenter d'enregistrer
  # cette base (qui n'a pas de schedule_expression) dans Sidekiq Cron.
  def self.schedulable?
    schedule_expression.present? && super
  end

  def perform
    scope.limit(MAX_DOSSIERS_PER_RUN).each(&:purge_discarded)
    self.class.perform_later if scope.exists?
  end

  private

  def scope = raise NotImplementedError
end
