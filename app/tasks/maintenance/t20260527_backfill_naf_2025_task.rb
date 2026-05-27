# frozen_string_literal: true

module Maintenance
  class T20260527BackfillNaf2025Task < MaintenanceTasks::Task
    # Backfill naf_2025 et libelle_naf_2025 pour les ~6M d'établissements existants.
    # Déduplique par SIRET : un seul appel API Entreprise v4 par SIRET unique,
    # puis update_all de tous les établissements partageant ce SIRET.

    include Dry::Monads[:result]

    # Reserve quota for normal traffic — backfill pauses when < 200 remaining.
    BACKFILL_REMAINING_THRESHOLD = 200
    BACKFILL_POOL = APIEntreprise::API::DEFAULT_POOL # etablissement endpoint = pool 250

    throttle_on(backoff: 1.minute) do
      remaining = APIEntreprise::RateLimiter.remaining(BACKFILL_POOL)
      remaining.present? && remaining < BACKFILL_REMAINING_THRESHOLD
    end

    def collection
      Etablissement
        .where(naf_2025: nil)
        .where.not(siret: nil)
        .distinct
        .pluck(:siret)
    end

    def process(siret)
      etablissement = Etablissement.where(siret:).joins(:dossier).merge(Dossier.joins(:procedure)).first
      etablissement ||= Etablissement.find_by(siret:)
      return if etablissement.nil?

      procedure_id = find_procedure_id(etablissement)
      return if procedure_id.nil?

      result = APIEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
      case result
      in Success(params) if params[:naf_2025].present?
        Etablissement.where(siret:).update_all(
          naf_2025: params[:naf_2025],
          libelle_naf_2025: params[:libelle_naf_2025]
        )
      else
        # API n'a pas retourné de données NAF 2025 — on laisse nil
      end
    rescue => e
      Sentry.capture_exception(e, extra: { siret: })
    end

    private

    def find_procedure_id(etablissement)
      (etablissement.dossier || etablissement.champ&.dossier)&.procedure&.id
    end
  end
end
