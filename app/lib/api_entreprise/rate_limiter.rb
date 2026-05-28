# frozen_string_literal: true

# Shared rate limiter for API Entreprise — per-pool.
#
# API Entreprise enforces rate limits by pool (identified by ratelimit-limit header):
#   - 250 req/min: most JSON endpoints (insee, dgfip/chiffres_affaires, infogreffe, etc.)
#   -  100 req/min: urssaf/attestation_vigilance
#   -   50 req/min: gip_mds/effectifs
#   -    5 req/min: dgfip/attestation_fiscale
#
# Server-driven approach: every HTTP response calibrates the local state from RateLimit-* headers.
#
#   calibrate!(response, pool) — SET remaining/reset from RateLimit-* headers (every response)
#   throttled?(pool)           — read-only check (Job#before_perform, BackfillTask#throttle_on)
#
# Redis keys: api_entreprise:rate_limit:{remaining|reset}:{pool}
# Keys auto-expire (TTL = reset window), so no stale state after window ends.
module APIEntreprise::RateLimiter
  KEY_PREFIX = "api_entreprise:rate_limit"

  def self.remaining_key(pool) = "#{KEY_PREFIX}:remaining:#{pool}"
  def self.reset_key(pool) = "#{KEY_PREFIX}:reset:#{pool}"

  def self.throttled?(pool)
    r = remaining(pool)
    r.present? && r <= 0
  end

  def self.remaining(pool)
    Kredis.redis.get(remaining_key(pool))&.to_i
  end

  def self.calibrate!(response, pool)
    headers = response&.try(:headers)
    return if headers.nil?

    remaining = headers['RateLimit-Remaining'] || headers['ratelimit-remaining']
    reset = headers['RateLimit-Reset'] || headers['ratelimit-reset']
    return if remaining.nil? || reset.nil?

    server_limit = headers['RateLimit-Limit'] || headers['ratelimit-limit']
    if server_limit && server_limit.to_i != pool
      Rails.logger.warn("APIEntreprise::RateLimiter pool mismatch: expected=#{pool} server=#{server_limit}")
    end

    # RateLimit-Reset is a Unix timestamp (UTC epoch seconds), same as Time.current.to_i — timezone-safe.
    ttl = [reset.to_i - Time.current.to_i, 1].max
    Kredis.redis.set(remaining_key(pool), remaining.to_i, ex: ttl)
    Kredis.redis.set(reset_key(pool), reset.to_i, ex: ttl) if remaining.to_i <= 0
  end

  def self.wait_duration(pool)
    reset_at = Kredis.redis.get(reset_key(pool))&.to_i
    return 2 if reset_at.nil? || reset_at == 0

    [reset_at - Time.current.to_i, 2].max
  end
end
