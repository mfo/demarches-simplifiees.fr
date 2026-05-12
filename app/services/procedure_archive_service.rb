# frozen_string_literal: true

require 'tempfile'

class ProcedureArchiveService
  def initialize(procedure)
    @procedure = procedure
  end

  def make_and_upload_archive(archive)
    dossiers = Dossier.archivable
      .where(groupe_instructeur: archive.groupe_instructeurs)

    dossiers = dossiers.where(processed_at: archive.month.to_datetime.all_month) if archive.monthly?

    attachments = ActiveStorage::DownloadableFile.create_list_from_dossiers(dossiers:, user_profile: archive.user_profile)

    DownloadableFileService.download_and_zip(@procedure, attachments, zip_root_folder(archive)) do |zip_filepath|
      ArchiveUploader.new(procedure: @procedure, filename: archive.filename(@procedure), filepath: zip_filepath)
        .upload(archive)
    end
  end

  private

  def zip_root_folder(archive)
    zip_filename = archive.filename(@procedure)

    [
      File.basename(zip_filename, File.extname(zip_filename)),
      archive.id,
    ].join("-")
  end
end
