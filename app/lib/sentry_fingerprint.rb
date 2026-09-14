# frozen_string_literal: true

# Sentry `before_send` hook grouping outages by their source.
#
# Sentry groups events by stacktrace and transaction, so a single Redis,
# PostgreSQL or object storage outage fans out into dozens of issues (one per
# controller action or job, times one per message variant: "Connection
# refused", "Connection timed out", "No route to host"…). Nothing in those
# issues is actionable in the code: they only need to be spotted, then closed
# once the outage is over. Forcing the fingerprint to the exception class makes
# every burst land in a single issue per class, which Sentry reopens as
# "regressed" the next time the component goes down.
#
# Two kinds of events are grouped: connection-level errors of our own
# infrastructure, by exception class; and availability errors of an external
# provider, by provider, when the exception says so by including
# ProviderOutage. Everything else (4xx, schema mismatches, mail delivery…)
# keeps the default grouping: those failures are per endpoint and per
# transaction.
module SentryFingerprint
  # Mixed into an exception meaning "an external provider is unavailable":
  # timeout, connection failure, 5xx, once the retries the caller allows are
  # spent. `provider` names the source (a job class, a champ type, an API
  # client) and becomes the issue: one per provider, whatever the message, the
  # transaction or the release. Errors that depend on the input (4xx, schema
  # mismatches) must not include it.
  module ProviderOutage
    attr_reader :provider
  end

  PROVIDER_OUTAGE_KEY = "provider-outage"

  INFRASTRUCTURE_ERRORS = [
    # Redis (Kredis, cache, Sidekiq)
    Redis::BaseConnectionError,
    RedisClient::ConnectionError,
    # PostgreSQL
    ActiveRecord::ConnectionNotEstablished,
    ActiveRecord::ConnectionFailed,
    PG::ConnectionBad,
    PG::UnableToSend,
    # Object storage (fog-openstack)
    Excon::Error::Socket,
    Excon::Error::Timeout,
    Excon::Error::Server,
  ].freeze

  # Raised while Redis restarts and is not serving reads yet; redis-client
  # maps READONLY and MASTERDOWN to connection errors but not LOADING.
  REDIS_LOADING_PREFIX = "LOADING"

  def self.call(event, hint)
    fingerprint = for_exception(hint[:exception])
    event.fingerprint = fingerprint if fingerprint
    event
  end

  def self.for_exception(exception)
    return if exception.nil?

    chain = Sentry::Utils::ExceptionCauseChain.exception_to_array(exception)

    infrastructure_error = chain.find { infrastructure_error?(it) }
    return [infrastructure_error.class.name] if infrastructure_error

    provider_outage = chain.find { it.is_a?(ProviderOutage) }
    [PROVIDER_OUTAGE_KEY, provider_outage.provider.to_s] if provider_outage
  end

  def self.infrastructure_error?(exception)
    case exception
    when Redis::CommandError, RedisClient::CommandError
      exception.message.start_with?(REDIS_LOADING_PREFIX)
    when *INFRASTRUCTURE_ERRORS
      true
    else
      false
    end
  end
  private_class_method :infrastructure_error?
end
