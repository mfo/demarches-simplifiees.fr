# frozen_string_literal: true

module APIEntreprise::HealthChecker
  PING_BASE_URL = "#{API_ENTREPRISE_URL}/ping"
  CACHE_KEY_PREFIX = "api_entreprise:health"
  CACHE_TTL = 5.minutes

  PROVIDERS = {
    insee_sirene: 'insee/sirene',
    infogreffe_rcs: 'infogreffe/rcs',
    european_commission_tva: 'european_commission/numero_tva',
    djepva_association: 'djepva/api-association',
    dgfip_chiffre_affaires: 'dgfip/chiffre_affaires',
    dgfip_attestation_fiscale: 'dgfip/attestation_fiscale',
    gip_mds_effectifs: 'gip_mds/effectifs',
    urssaf_attestation_sociale: 'urssaf/attestation_sociale',
    banque_de_france_bilans: 'banque_de_france/bilans'
  }.freeze

  # ok = provider works correctly
  # unknown = insufficient data to determine status (HTTP 200, fail-open by design)
  UP_STATUSES = %w[ok unknown].freeze

  def self.provider_up?(provider)
    ping_key = provider.is_a?(Symbol) ? PROVIDERS.fetch(provider) : provider
    status = cached_status(ping_key)
    return true if status.nil? # fail-open: cache empty or Redis down
    status.in?(UP_STATUSES)
  end

  def self.refresh_all!
    hydra = Typhoeus::Hydra.new
    PROVIDERS.each_value do |key|
      request = Typhoeus::Request.new("#{PING_BASE_URL}/#{key}", timeout: 5)
      request.on_complete { |response| store_response(key, response) }
      hydra.queue(request)
    end
    hydra.run
  end

  def self.cached_status(ping_key)
    Kredis.redis.get(cache_key(ping_key))
  end

  def self.cache_key(ping_key)
    "#{CACHE_KEY_PREFIX}:#{ping_key}"
  end

  def self.store_response(ping_key, response)
    status = JSON.parse(response.body)['status']
    Kredis.redis.set(cache_key(ping_key), status, ex: CACHE_TTL.to_i)
    status
  rescue JSON::ParserError => e
    Rails.logger.error("HealthChecker: JSON parse error for #{ping_key}: #{e.message}")
    Sentry.capture_exception(e)
    nil
  rescue => e
    Rails.logger.error("HealthChecker: refresh failed for #{ping_key}: #{e.class} #{e.message}")
    Sentry.capture_exception(e)
    nil
  end
end
