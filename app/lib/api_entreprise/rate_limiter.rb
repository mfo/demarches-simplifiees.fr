# frozen_string_literal: true

# Shared rate limiter for API Entreprise (250 req/min).
#
# Hybrid approach: Redis DECR for proactive counting + server headers for calibration.
#
#   consume!    — DECR before each HTTP call (API#call)
#   calibrate!  — SET from RateLimit-* headers (~10% of 200s, 100% of 429s)
#   throttled?  — read-only check (Job#before_perform, BackfillNaf2025Task#throttle_on)
#
# Flow:
#   1. Job#before_perform checks throttled? → if true, re-enqueue + free worker
#   2. API#call calls consume! (atomic DECR)
#   3. API#call calls calibrate! on response (recalibrates from server truth)
#   4. BackfillNaf2025Task#throttle_on checks throttled? → pauses if remaining < 200
#
# Redis keys auto-expire (TTL = reset window), so no stale state after window ends.
module APIEntreprise::RateLimiter
  REMAINING_KEY = "api_entreprise:rate_limit:remaining"
  RESET_KEY = "api_entreprise:rate_limit:reset"
  def self.throttled?
    remaining = Kredis.redis.get(REMAINING_KEY)
    remaining.present? && remaining.to_i <= 0
  end

  # Called by API#call before each HTTP request.
  # Atomically decrements the remaining counter.
  # Returns without blocking — callers decide what to do when throttled.
  def self.consume!
    remaining = Kredis.redis.get(REMAINING_KEY)
    return if remaining.nil? # not yet calibrated, let it through

    Kredis.redis.decr(REMAINING_KEY)
  end

  # Called by API#call after receiving a response.
  # Recalibrates Redis from server-provided RateLimit-* headers.
  # Called on every 429, and ~10% of 200s to let DECR do its job.
  def self.calibrate!(response)
    headers = response&.try(:headers)
    return if headers.nil?

    remaining = headers['RateLimit-Remaining']
    reset = headers['RateLimit-Reset']
    return if remaining.nil? || reset.nil?

    ttl = [reset.to_i - Time.current.to_i, 1].max
    Kredis.redis.set(REMAINING_KEY, remaining.to_i, ex: ttl)
    Kredis.redis.set(RESET_KEY, reset.to_i, ex: ttl) if remaining.to_i <= 0
  end

  # Seconds until the rate limit window resets.
  # Used by Job#before_perform to schedule re-enqueue delay.
  def self.wait_duration
    reset_at = Kredis.redis.get(RESET_KEY)&.to_i
    return 2 if reset_at.nil? || reset_at == 0

    [reset_at - Time.current.to_i, 2].max
  end
end
