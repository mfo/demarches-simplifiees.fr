# frozen_string_literal: true

# Devise persists the "return to" URL after an authentication failure into the
# session cookie (`user_return_to`, `super_admin_return_to`, ...). Our session
# store is a 4 KB cookie (:cookie_store), so an oversized URL — a prefill /
# `commencer` link carrying many champ query params, or a bot hammering
# /manager with a giant query string — overflows the cookie and raises
# ActionDispatch::Cookies::CookieOverflow (see Sentry RAILS-JYR).
#
# We cap the stored location: anything larger than MAX_STORED_LOCATION_BYTES is
# not stored, so the user simply lands on the default post-login page instead of
# crashing the request (or getting their whole session wiped by
# CookieOverflowHandler). Prepending onto the shared StoreLocation module covers
# both application controllers and Devise::FailureApp.
#
# 1024 is chosen so two concurrent *_return_to keys plus the rest of the session
# still fit the ~2.7 KB plaintext budget that the encrypted cookie leaves us.
module Devise
  module Controllers
    module StoreLocationCap
      MAX_STORED_LOCATION_BYTES = 1024

      def store_location_for(resource_or_scope, location)
        if location && location.to_s.bytesize > MAX_STORED_LOCATION_BYTES
          scope = Devise::Mapping.find_scope!(resource_or_scope)
          Rails.logger.info("[StoreLocationCap] skipped oversized return-to for #{scope} (#{location.to_s.bytesize} bytes > #{MAX_STORED_LOCATION_BYTES})")
          return
        end

        super
      end
    end
  end
end

Devise::Controllers::StoreLocation.prepend(Devise::Controllers::StoreLocationCap)
