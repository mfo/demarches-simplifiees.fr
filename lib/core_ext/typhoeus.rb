# frozen_string_literal: true

# Send tracing headers on the CONNECT request to the outbound proxy (squid),
# so its access log can tie each call back to a web request or a job.
# Headers are set on the easy handle rather than in request.options, so the
# Typhoeus cache key stays stable across requests.
module Typhoeus
  class EasyFactory
    module ProxyTracingHeaders
      def get
        super.tap do |easy|
          headers = {
            'X-Request-Id' => Current.request_id,
            'X-Job-Id' => Current.job_id,
          }.compact

          easy.proxy_headers = headers if headers.present?
        end
      end
    end

    prepend ProxyTracingHeaders
  end
end
