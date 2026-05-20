# frozen_string_literal: true

describe CsvParsingConcern, type: :controller do
  controller(ApplicationController) do
    include CsvParsingConcern
  end

  describe '#validate_csv_upload' do
    subject { controller.validate_csv_upload(file) }

    context 'when file is a valid CSV under the size limit' do
      let(:file) { fixture_file_upload('spec/fixtures/files/modele-import-referentiel.csv', 'text/csv') }

      it { is_expected.to eq(:ok) }
    end

    context 'when file exceeds max size' do
      let(:file) { fixture_file_upload('spec/fixtures/files/modele-import-referentiel.csv', 'text/csv') }

      before { allow(file).to receive(:size).and_return(CsvParsingConcern::CSV_MAX_SIZE + 1) }

      it { is_expected.to eq(:too_large) }

      it 'does not sniff the content type' do
        expect(Marcel::MimeType).not_to receive(:for)
        subject
      end
    end

    context 'when a binary file is uploaded with text/csv declared content type' do
      let(:file) { fixture_file_upload('spec/fixtures/files/french-flag.gif', 'text/csv') }

      it { is_expected.to eq(:not_csv) }
    end

    context 'when a valid CSV is uploaded with application/vnd.ms-excel declared content type' do
      let(:file) { fixture_file_upload('spec/fixtures/files/modele-import-referentiel.csv', 'application/vnd.ms-excel') }

      it { is_expected.to eq(:ok) }
    end
  end
end
