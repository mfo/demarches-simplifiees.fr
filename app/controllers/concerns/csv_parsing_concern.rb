# frozen_string_literal: true

module CsvParsingConcern
  extend ActiveSupport::Concern

  CSV_MAX_SIZE = 1.megabyte
  CSV_MAX_LINES = 5_000
  CSV_ACCEPTED_CONTENT_TYPES = [
    "text/csv",
    "application/vnd.ms-excel",
  ].freeze

  def validate_csv_upload(file)
    return :too_large if file.size > CSV_MAX_SIZE
    return :not_csv unless CSV_ACCEPTED_CONTENT_TYPES.include?(sniff_content_type(file))
    :ok
  end

  private

  def sniff_content_type(file)
    io = file.tempfile.tap(&:rewind)
    Marcel::MimeType.for(io, name: file.original_filename, declared_type: file.content_type)
  ensure
    file.tempfile&.rewind
  end

  def parse_csv(file, strings_as_keys: true, keep_original_headers: false, convert_values_to_numeric: false)
    raw_content = file.read

    utf8_content = ensure_utf8(raw_content)

    Tempfile.create(['referentiel', '.csv'], encoding: 'UTF-8') do |tempfile|
      tempfile.write(utf8_content)
      tempfile.rewind

      begin
        SmarterCSV.process(
          tempfile.path,
          strings_as_keys:,
          keep_original_headers:,
          convert_values_to_numeric:
        )
      rescue *[CSV::MalformedCSVError, SmarterCSV::NoColSepDetected, ArgumentError]
        []
      end
    end
  end

  def ensure_utf8(content)
    detection = CharlockHolmes::EncodingDetector.detect(content)
    source_encoding = detection[:encoding] || 'Windows-1252'
    CharlockHolmes::Converter.convert(content, source_encoding, 'UTF-8')
  end
end
