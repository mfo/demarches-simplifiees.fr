# frozen_string_literal: true

class APIEntreprise::Job < ApplicationJob
  include Dry::Monads[:result]

  queue_as :default

  use_sidekiq_retry

  # If by the time the job runs the Etablissement has been deleted
  # (it can happen through EtablissementUpdateJob for instance), ignore the job
  discard_on ActiveRecord::RecordNotFound

  # If rate limited, re-enqueue with delay and free the worker immediately.
  before_perform do
    if APIEntreprise::RateLimiter.throttled?
      wait = APIEntreprise::RateLimiter.wait_duration
      self.class.set(wait: wait.seconds).perform_later(*arguments)
      throw :abort
    end
  end

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

  # Centralizes monad unwrap for adapter results.
  # Success(params) with data → yields params to block
  # Success({}) → no-op (resource not found, nothing to update)
  # Failure(retryable: true) → re-raises to trigger job retry
  # Failure(retryable: false) → logs and no-op (forbidden, 451, etc.)
  def with_adapter(adapter)
    result = adapter.to_params

    case result
    in Success(params) if params.present?
      yield params
    in Success
      nil
    in Failure(retryable: true, type: :rate_limited, code:, **)
      wait = APIEntreprise::RateLimiter.wait_duration(api_pool)
      self.class.set(wait: wait.seconds).perform_later(*arguments)
    in Failure(retryable: true, type:, code:, raw_response:, **)
      raise StandardError, format_error(type, code, raw_response)
    in Failure(retryable: false, type:, code:, **)
      Rails.logger.info("APIEntreprise non-retryable failure: type=#{type} code=#{code}")
      nil
    else
      raise "Unexpected adapter result: #{result.inspect}"
    end
  end

  private

  def format_error(type, code, raw_response)
    message = "API Entreprise error: type=#{type} code=#{code}"
    if raw_response.present?
      uri = URI.parse(raw_response.effective_url) rescue nil
      message += " url=#{uri&.host}#{uri&.path} body=#{raw_response.body.truncate(500)}"
    end
    message
  end
end
