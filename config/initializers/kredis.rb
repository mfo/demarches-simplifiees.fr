# frozen_string_literal: true

redis_shared_options = {
  url: ENV['REDIS_CACHE_URL'], # will fallback to default redis url if empty, and won't fail if there is no redis server
  ssl: ENV['REDIS_CACHE_SSL'] == 'enabled',
  connect_timeout: 0.2,
}
redis_shared_options[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if ENV['REDIS_CACHE_SSL_VERIFY_NONE'] == 'enabled'

# Parallel test processes share one Redis server but must not share keys:
# Kredis keys embed record ids, which overlap across per-process databases.
# Give each process its own Redis logical database (db 0 stays for dev/serial runs).
if Rails.env.test? && ENV['TEST_ENV_NUMBER'].present?
  redis_shared_options[:db] = ENV['TEST_ENV_NUMBER'].to_i
end

Kredis::Connections.connections[:shared] = Redis.new(redis_shared_options)
