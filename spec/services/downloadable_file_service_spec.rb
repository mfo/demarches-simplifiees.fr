# frozen_string_literal: true

describe DownloadableFileService do
  include ZipHelpers

  let(:procedure) { create(:procedure, :published) }
  let(:service) { ProcedureArchiveService.new(procedure) }

  before do
    FileUtils.mkdir_p('/tmp/test_archive_creation')
    stub_const("DownloadableFileService::ARCHIVE_CREATION_DIR", '/tmp/test_archive_creation')
  end

  describe '#download_and_zip' do
    let(:archive) { build(:archive, id: '3') }
    let(:filename) { service.send(:zip_root_folder, archive) }

    it 'create a tmpdir while block is running' do
      previous_dir_list = Dir.entries(DownloadableFileService::ARCHIVE_CREATION_DIR)

      DownloadableFileService.download_and_zip(procedure, [], filename) do |_zip_file|
        new_dir_list = Dir.entries(DownloadableFileService::ARCHIVE_CREATION_DIR)
        expect(previous_dir_list).not_to eq(new_dir_list)
      end
    end

    it 'cleans up its tmpdir after block execution' do
      expect { DownloadableFileService.download_and_zip(procedure, [], filename) { |zip_file| } }
        .not_to change { Dir.entries(DownloadableFileService::ARCHIVE_CREATION_DIR) }
    end

    it 'creates a zip with zip utility' do
      expected_zip_path = File.join(DownloadableFileService::ARCHIVE_CREATION_DIR, "#{service.send(:zip_root_folder, archive)}.zip")
      expect(DownloadableFileService).to receive(:system).with('zip', '-0', '-r', '-UN=UTF8', expected_zip_path, an_instance_of(String), chdir: an_instance_of(String))
      DownloadableFileService.download_and_zip(procedure, [], filename) { |zip_path| }
    end

    it 'cleans up its generated zip' do
      expected_zip_path = File.join(DownloadableFileService::ARCHIVE_CREATION_DIR, "#{service.send(:zip_root_folder, archive)}.zip")
      DownloadableFileService.download_and_zip(procedure, [], filename) do |_zip_path|
        expect(File.exist?(expected_zip_path)).to be_truthy
      end
      expect(File.exist?(expected_zip_path)).to be_falsey
    end

    context 'when attachments target the same path' do
      def fake_attachment(content, id)
        ActiveStorage::FakeAttachment.new(
          file: StringIO.new(content),
          filename: 'test.pdf',
          name: 'pdf_export_for_instructeur',
          id:,
          created_at: Time.zone.now
        )
      end

      let(:attachments) do
        [
          [fake_attachment('fichier 1', 1), 'dossier-1/test.pdf'],
          [fake_attachment('fichier 2', 2), 'dossier-1/test.pdf'],
          [fake_attachment('fichier 3', 3), 'dossier-1/test.pdf'],
        ]
      end

      it 'deduplicates paths so no file is overwritten' do
        DownloadableFileService.download_and_zip(procedure, attachments, filename) do |zip_path|
          entries = read_zip_entries(zip_path)
          expect(entries).to include('export/dossier-1/test.pdf', 'export/dossier-1/test-2.pdf', 'export/dossier-1/test-3.pdf')
          expect(read_zip_file_content(zip_path, 'export/dossier-1/test.pdf')).to eq('fichier 1')
          expect(read_zip_file_content(zip_path, 'export/dossier-1/test-2.pdf')).to eq('fichier 2')
          expect(read_zip_file_content(zip_path, 'export/dossier-1/test-3.pdf')).to eq('fichier 3')
        end
      end
    end
  end
end
