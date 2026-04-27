# frozen_string_literal: true

module Maintenance
  class T20260427backfillVirusScanBlobsTask < MaintenanceTasks::Task
    # Traite le stock de blobs bloqués en virus_scan_result "pending".
    # Le CRON FixMissingAntivirusAnalysisJob gère le flux (blobs récents),
    # cette tâche gère le stock (backlog ancien).
    #
    # Inclut les orphelins (sans attachment) : BlobProcessorJob les marquera
    # simplement comme processed, et PurgeUnattachedBlobsJob les purgera.
    # On évite ainsi le semi-join sur 103M attachments qui timeout.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      ActiveStorage::Blob
        .where(virus_scan_result: ActiveStorage::VirusScanner::PENDING)
    end

    def process(blob)
      return if blob.metadata["processed"]

      BlobProcessorJob.perform_later(blob)
    end

    # pas de count : la requête sur 7M+ rows timeout même avec statement_timeout élevé
  end
end
