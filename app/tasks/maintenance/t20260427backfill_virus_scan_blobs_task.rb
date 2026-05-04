# frozen_string_literal: true

module Maintenance
  class T20260427backfillVirusScanBlobsTask < MaintenanceTasks::Task
    # Traite le stock de blobs bloqués en virus_scan_result "pending".
    # Le CRON FixMissingAntivirusAnalysisJob gère le flux (blobs récents),
    # cette tâche gère le stock (backlog ancien).
    #
    # Inclut les orphelins (sans attachment) : BlobProcessorJob les marquera
    # simplement comme processed, et PurgeUnattachedBlobsJob les purgera.
    #
    # Utilise l'index composite (virus_scan_result, id DESC) pour itérer
    # efficacement sur les ~7M blobs pending, du plus récent au plus ancien.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    throttle_on(backoff: 1.minute) do
      Sidekiq::Queue.new("default").size > 100 || Sidekiq::Queue.new("low").size > 1_000
    end

    def collection
      ActiveStorage::Blob.where(virus_scan_result: ActiveStorage::VirusScanner::PENDING).in_batches(of: 100, order: :desc)
    end

    def process(batch)
      excluded_ids = ActiveStorage::Attachment
        .where(blob_id: batch.select(:id))
        .where("record_type = ? OR name = ?", "ActiveStorage::Attachment", "preview_image")
        .pluck(:blob_id)

      scope = batch
      scope = scope.where.not(id: excluded_ids) if excluded_ids.any?

      scope.find_each do |blob|
        next if blob.metadata["processed"]

        BlobProcessorJob.perform_later(blob)
      end
    end
  end
end
