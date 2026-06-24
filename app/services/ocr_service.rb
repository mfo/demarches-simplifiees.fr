# frozen_string_literal: true

class OCRService
  include Dry::Monads[:result]
  extend Dry::Monads[:result]

  TWO_D_DOC_ENDPOINT = "/api/v1/workflows/document-barcode-extraction/execute-sync"

  def self.analyze(blob, nature:)
    blob_url = blob.url
    case nature
    when "rib"                    then analyze_rib(blob_url)
    when "justificatif_domicile"  then analyze_2ddoc(blob_url, nature)
    else raise ArgumentError, "OCRService: unknown nature '#{nature}'"
    end
  end

  private

  def self.analyze_rib(blob_url)
    return not_configured("OCR_SERVICE_URL") if ocr_url.nil?

    json = { "url": blob_url, "hint": { "type": "rib" } }
    headers = { 'X-Remote-File': blob_url } # needed for logging

    API::Client.new.call(url: ocr_url, method: :post, headers:, json:, timeout: 31)
      .fmap { |ok| { value_json: ok.body } } # store directly in value_json without transformation
      .or { to_not_retryable_failure(it) }
  end

  def self.analyze_2ddoc(blob_url, nature)
    return not_configured('DOCUMENT_IA_URL') if document_ia_url.nil?

    url = document_ia_url + TWO_D_DOC_ENDPOINT
    headers = { 'X-API-KEY': ENV.fetch('DOCUMENT_IA_KEY') }
    body = { file_url: blob_url }

    API::Client.new.call(url:, headers:, method: :post, body:, timeout: 31)
      .fmap { |ok| { data: ok.body, value_json: extract_2ddoc(ok.body, nature) } }
      .or { to_not_retryable_failure(it) }
  end

  def self.extract_2ddoc(body, nature)
    case nature
    when "justificatif_domicile" then extract_justif_domicile(body)
    end
  end

  def self.first_valid_2ddoc(body)
    body
      .dig(:data, :result, :barcodes)
      &.find { it[:type] == '2D_DOC' && it[:is_valid] } # take the first valid 2ddoc
  end

  TWODDOC_MAPPING = {
    beneficiary: 10, # Quality / Name / FirstName
    ligne_2: 20,
    ligne_3: 21,
    ligne_4: 22,
    ligne_5: 23,
    code_postal: 24,
    localite: 25,
  }

  def self.extract_justif_domicile(body)
    doc_type, raw_issue_date, raw_data = first_valid_2ddoc(body)
      &.fetch_values(:doc_type, :issue_date, :raw_data)

    return nil if raw_data.nil? || !justif_domicile?(doc_type)

    # format : '2026-01-02'
    issue_date = raw_issue_date&.then { Date.strptime(it, '%Y-%m-%d') }
    beneficiary = raw_data[:"10"]&.tr('/', ' ')

    attr = {
      beneficiary:,
      issue_date:,
      two_ddoc: true,
    }

    query = TWODDOC_MAPPING
      .fetch_values(:ligne_2, :ligne_3, :ligne_4, :ligne_5, :code_postal, :localite)
      .map { raw_data[it.to_s.to_sym] }
      .compact_blank
      .join(' ')

    fetch_ban_address(query)
      .fmap { attr.merge!(it.except(:geometry)) }

    # force parsing to ensure compat
    JustificatifDomicile.new(attr).attributes.compact
  end

  def self.justif_domicile?(doc_type) = doc_type.in?(['00', '01', '02'])

  MIN_BAN_CONFIDENCE = 0.9

  # TODO: check if enough 2ddoc properly stode postal_code
  # and if enough at least call api geo to fetch region / departement
  def self.fetch_ban_address(query)
    return Failure(:no_query) if query.blank?

    API::Client.new.call(url: "#{API_ADRESSE_URL}/search", params: { q: query, limit: 1 })
      .fmap { it.body[:features]&.first }
      .bind { it.present? ? Success(it) : Failure(:no_feature) }
      .bind { it[:properties][:score] >= MIN_BAN_CONFIDENCE ? Success(it) : Failure(:bad) }
      .fmap { APIGeoService.parse_ban_address(it.deep_stringify_keys) }
  end

  def self.ocr_url = ENV.fetch("OCR_SERVICE_URL", nil)
  def self.document_ia_url = ENV.fetch("DOCUMENT_IA_URL", nil)

  def self.not_configured(message)
    Failure(retryable: false, error: StandardError.new("#{message} not configured"))
  end

  def self.to_not_retryable_failure(data)
    case data
    in code:, error:
      Failure(retryable: false, error:, code:)
    else
      Failure(retryable: false, error: StandardError.new('Unknown error'))
    end
  end
end
