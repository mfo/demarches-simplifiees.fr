# frozen_string_literal: true

module Maintenance
  class RegenerateAttestationTask < MaintenanceTasks::Task
    # Régénère l'attestation de dossiers, par exemple
    # si le PDF a été enregistré en base
    # mais dont l'upload vers l'object storage a échoué
    # (Excon::Error::ServiceUnavailable 503, issue Sentry RAILS-KR7).
    #
    # L'attestation existante (record + blob/attachment cassé) est supprimée,
    # puis régénérée via AttestationPdfGenerationJob.
    #
    # **Attention**:
    #   utilise la dernière version de l'attestation,
    #   pas nécessairement celle en vigueur au moment
    #   où le dossier a été traité!
    #
    # dossier_ids : liste d'ids séparés par des virgules et/ou espaces.

    attribute :dossier_ids, :string
    validates :dossier_ids, presence: true

    def collection
      Dossier.where(id: parsed_dossier_ids)
    end

    def process(dossier)
      dossier.attestation&.destroy!
      AttestationPdfGenerationJob.perform_later(dossier)
    end

    def count
      collection.count
    end

    private

    def parsed_dossier_ids
      dossier_ids.to_s.split(/[\s,]+/).map(&:to_i).reject(&:zero?)
    end
  end
end
