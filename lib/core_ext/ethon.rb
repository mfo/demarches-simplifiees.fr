# frozen_string_literal: true

# Expose libcurl's CURLOPT_PROXYHEADER, missing from Ethon: headers sent only
# on the CONNECT request to a proxy, never to the target server.
Ethon::Curls::Options.option(:easy, :proxyheader, :ffipointer, 228)

module Ethon
  class Easy
    module ProxyHeaders
      attr_reader :proxy_headers

      # Same slist handling as Ethon::Easy::Header#headers=
      def proxy_headers=(headers)
        @proxy_headers = headers
        list = nil
        headers.each do |k, v|
          list = Curl.slist_append(list, Util.escape_zero_byte("#{k}: #{v}"))
        end
        Curl.set_option(:proxyheader, list, handle)

        @proxy_header_list = list && FFI::AutoPointer.new(list, Curl.method(:slist_free_all))
      end
    end

    include ProxyHeaders
  end
end
