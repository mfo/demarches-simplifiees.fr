# frozen_string_literal: true

Typhoeus::Config.user_agent = APPLICATION_NAME

Rails.application.config.after_initialize do
  Typhoeus::Config.cache = Typhoeus::Cache::SuccessfulRequestsRailsCache.new
end

# The only hook that sees every outgoing call: the ~20 direct Typhoeus.get/post
# call sites, the API::Client consumers, and the Hydras. Typhoeus::Trace is
# resolved inside the block rather than here, so the constant is autoloaded on
# first call rather than during initialization, and code reloading picks it up.
if Rails.env.development?
  Typhoeus.on_complete { |response| Typhoeus::Trace.log(response) }
end
