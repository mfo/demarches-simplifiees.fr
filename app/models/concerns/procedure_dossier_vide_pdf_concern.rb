# frozen_string_literal: true

# Caches the generated "dossier vide" PDF (the printable empty form) in Active Storage
module ProcedureDossierVidePdfConcern
  extend ActiveSupport::Concern

  included do
    has_one_attached :dossier_vide_pdf
  end

  CACHE_KEY_METADATA = 'dossier_vide_pdf_cache_key'
  # Bump when the PDF rendering changes (component, helpers, stylesheet) and the
  # already cached PDF should be invalidated without waiting for the expiration.
  CACHE_VERSION = 1
  CACHE_EXPIRATION = 1.week

  def dossier_vide_pdf_cache_key_for(revision)
    ["v#{CACHE_VERSION}", *[self, revision, service].compact.map(&:cache_key_with_version)].join('/')
  end

  def dossier_vide_pdf_fresh?(cache_key)
    blob = dossier_vide_pdf.blob
    return false if blob.nil?

    blob.metadata[CACHE_KEY_METADATA] == cache_key && blob.created_at.after?(CACHE_EXPIRATION.ago)
  end

  def store_dossier_vide_pdf(pdf, cache_key:)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(pdf),
      filename: "#{libelle}.pdf",
      content_type: 'application/pdf',
      metadata: {
        'virus_scan_result' => ActiveStorage::VirusScanner::SAFE,
        CACHE_KEY_METADATA => cache_key,
      }
    )

    # Attaching touches the procedure, which would invalidate the key just stored
    Procedure.no_touching { dossier_vide_pdf.attach(blob) }
  end
end
