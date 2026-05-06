# frozen_string_literal: true

module ActiveJob::RetryOnStandardError
  extend ActiveSupport::Concern

  MAX_ATTEMPTS_JOBS = ENV.fetch("MAX_ATTEMPTS_JOBS", 25).to_i

  class_methods do
    # Opt out of Active Job's retry_on StandardError and rely on Sidekiq's
    # native retry mechanism instead. Useful for long-running jobs where
    # Sidekiq's retry semantics (server-side, surviving deploys) fit better.
    def use_sidekiq_retry
      self.rescue_handlers = rescue_handlers.reject { |klass_name, _| klass_name == "StandardError" }
      sidekiq_options retry: MAX_ATTEMPTS_JOBS
    end
  end

  included do
    # Disable Sidekiq retries so only Active Job's retry_on applies.
    # Without this, Sidekiq would retry the job after Active Job exhausts retries,
    # causing many more executions (activejob retries × Sidekiq default 25 retries).
    sidekiq_options retry: false

    retry_on StandardError, attempts: MAX_ATTEMPTS_JOBS, wait: :polynomially_longer
  end
end
