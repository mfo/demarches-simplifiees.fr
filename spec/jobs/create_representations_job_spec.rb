# frozen_string_literal: true

describe CreateRepresentationsJob, :external_deps, type: :job do
  let(:procedure) do
    create(:procedure).tap { allow(_1).to receive(:valid?).and_return(true) }
  end

  let(:file) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }

  let(:blob) do
    procedure.notice.attach(file)
    procedure.notice.blob
  end

  before do
    require "vips"
    allow(ClamavService).to receive(:safe_file?).and_return(true)
    # Ensure blob is virus-scanned so we can test representations
    blob.update_columns(virus_scan_result: ActiveStorage::VirusScanner::SAFE)
  end

  context 'when attachment is representable' do
    it 'creates blob representation' do
      expect { described_class.perform_now(blob) }.to change { ActiveStorage::VariantRecord.count }.by(1)
    end
  end

  context 'when type image is rare (TIFF)' do
    let(:file) { fixture_file_upload('spec/fixtures/files/pencil.tiff', 'image/tiff') }

    it 'creates two variants' do
      expect { described_class.perform_now(blob) }.to change { ActiveStorage::VariantRecord.count }.by(2)
    end
  end

  context 'when file is a PDF' do
    let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }

    it 'creates blob representation' do
      expect { described_class.perform_now(blob) }.to change { ActiveStorage::VariantRecord.count }.by(1)
    end
  end

  context 'when blob is nil' do
    it 'does nothing' do
      expect { described_class.perform_now(nil) }.not_to change { ActiveStorage::VariantRecord.count }
    end
  end

  context 'when Vips raises an error' do
    before do
      allow_any_instance_of(ActiveStorage::Attachment).to receive(:representable?).and_return(true)
      allow_any_instance_of(ActiveStorage::Attachment).to receive(:representation)
        .and_raise(Vips::Error.new("unable to load source"))
    end

    it 're-enqueues the job for retry' do
      expect {
        described_class.perform_now(blob)
      }.to have_enqueued_job(described_class).with(blob)
    end
  end
end
