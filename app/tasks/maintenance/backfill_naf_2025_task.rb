# frozen_string_literal: true

module Maintenance
  class BackfillNaf2025Task < MaintenanceTasks::Task
    # Backfill etablissements not yet fetched with v4 API.
    # Uses naf_2025 IS NULL as marker for "never fetched with v4".
    # Re-fetches ALL data (not just naf_2025) to also repair etablissements
    # with partial data from the pre-monads era where 429s were silently
    # swallowed as 404s (see PR #13101).

    include RunnableOnDeployConcern
    include Dry::Monads[:result]

    throttle_on(backoff: 2.seconds) do
      remaining = Kredis.redis.get(APIEntreprise::API::RATE_LIMIT_REMAINING_KEY)
      remaining.present? && remaining.to_i <= 0
    end

    def collection
      Etablissement.where(naf_2025: nil).where.not(siret: nil)
    end

    def process(etablissement)
      procedure_id = etablissement.dossier&.procedure&.id || etablissement.champ&.dossier&.procedure&.id
      return if procedure_id.nil?

      result = APIEntreprise::EtablissementAdapter.new(etablissement.siret, procedure_id).to_params

      case result
      in Success(params) if params.present?
        etablissement.update_columns(params)
      else
        nil
      end
    rescue => e
      Rails.logger.error("BackfillNaf2025Task: #{etablissement.id}: #{e.message}")
      Sentry.capture_exception(e, extra: { etablissement_id: etablissement.id })
    end

    def count
      collection.count
    end
  end
end
