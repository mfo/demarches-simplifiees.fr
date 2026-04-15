# frozen_string_literal: true

# Alias for apps using `inflect.acronym 'URL'` —
# Rails resolves `validates :field, url: true` to URLValidator
URLValidator = HrefSanitizer::UrlValidator

HrefSanitizer.configure do |config|
  config.on_unsafe_url = -> (url, reason) { Rails.logger.warn("[href_sanitizer] Blocked #{reason}: #{url}") }
end
