# frozen_string_literal: true

# A fetch from an external provider that failed for a reason a retry may fix:
# timeout, connection failure, 5xx. `cause` is the failure being retried, an
# exception or a message when there is none.
class RetryableFetchError < StandardError
  include SentryFingerprint::ProviderOutage

  attr_reader :cause

  def initialize(cause, provider:)
    @cause = cause if cause.is_a?(Exception)
    @provider = provider
    super(cause.is_a?(Exception) ? cause.message : cause)
  end
end
