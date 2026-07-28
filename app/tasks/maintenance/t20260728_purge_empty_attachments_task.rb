# frozen_string_literal: true

module Maintenance
  class T20260728PurgeEmptyAttachmentsTask < MaintenanceTasks::Task
    # Nettoie les pièces jointes de 0 octet déjà présentes en base. Elles sont
    # inexploitables : AttachmentProcessorConcern ignore les blobs vides, donc
    # elles restent affichées « Analyse antivirus en cours… », ni visualisables
    # ni téléchargeables.
    #
    # EmptyFileValidator empêche d'en créer de nouvelles, et exempte celles déjà
    # enregistrées pour ne pas bloquer leur porteur : cette tâche n'est donc pas
    # un prérequis du déploiement, elle peut être lancée à la main quand on veut.
    #
    # Les variantes et les aperçus PDF sont exclus : ils sont dérivés d'un blob
    # déjà scanné et seront regénérés à la demande.

    include RunnableOnDeployConcern

    throttle_on(backoff: 1.minute) do
      Sidekiq::Queue.new("default").size > 100 || Sidekiq::Queue.new("low").size > 1_000
    end

    def collection
      ActiveStorage::Attachment
        .joins(:blob)
        .where(active_storage_blobs: { byte_size: 0 })
        .where.not(record_type: 'ActiveStorage::VariantRecord')
        .where.not(name: 'preview_image')
    end

    def process(attachment)
      attachment.purge_later
    end
  end
end
