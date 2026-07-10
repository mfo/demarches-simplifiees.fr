# frozen_string_literal: true

class DownloadableFileService
  ARCHIVE_CREATION_DIR = ENV.fetch('ARCHIVE_CREATION_DIR') { '/tmp' }
  EXPORT_DIRNAME = 'export'

  def self.download_and_zip(procedure, attachments, filename, &block)
    attachments = deduplicate_paths(attachments)

    Dir.mktmpdir(nil, ARCHIVE_CREATION_DIR) do |tmp_dir|
      export_dir = File.join(tmp_dir, EXPORT_DIRNAME)
      zip_path = File.join(ARCHIVE_CREATION_DIR, "#{filename}.zip")

      begin
        FileUtils.remove_entry_secure(export_dir) if Dir.exist?(export_dir)
        Dir.mkdir(export_dir)

        download_manager = DownloadManager::ProcedureAttachmentsExport.new(procedure, attachments, export_dir)
        download_manager.download_all

        File.delete(zip_path) if File.exist?(zip_path)
        system 'zip', '-0', '-r', '-UN=UTF8', zip_path, EXPORT_DIRNAME, chdir: tmp_dir
        yield(zip_path)
      ensure
        FileUtils.remove_entry_secure(export_dir) if Dir.exist?(export_dir)
        File.delete(zip_path) if File.exist?(zip_path)
      end
    end
  end

  # attachments with the same path (ex: same original filename) would silently
  # overwrite each other in the export dir: suffix duplicates before download
  def self.deduplicate_paths(attachments)
    used_paths = Set.new

    attachments.map do |attachment, path|
      deduplicated_path = path
      counter = 1

      until used_paths.add?(deduplicated_path)
        counter += 1
        extension = File.extname(path)
        deduplicated_path = "#{path.delete_suffix(extension)}-#{counter}#{extension}"
      end

      [attachment, deduplicated_path]
    end
  end
end
