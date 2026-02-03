# frozen_string_literal: true

module ActiveJob::RetryOnStandardError
  extend ActiveSupport::Concern

  included do
    # Disable Sidekiq retries so only Active Job's retry_on applies.
    # Without this, Sidekiq would retry the job after Active Job exhausts retries,
    # causing many more executions (activejob retries × Sidekiq default 25 retries).
    sidekiq_options retry: false

    retry_on StandardError, attempts: (ENV.fetch("MAX_ATTEMPTS_JOBS", 25).to_i), wait: :polynomially_longer
  end
end
