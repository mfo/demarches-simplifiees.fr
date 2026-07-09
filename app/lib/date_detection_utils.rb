# frozen_string_literal: true

module DateDetectionUtils
  TIMESTAMP_STRING_REGEXP = /^[-+]?\d{10,13}(\.\d+)?$/
  TIMESTAMP_MIN = -2_208_988_800 # 1900-01-01 00:00:00 UTC
  TIMESTAMP_MAX = 4_102_444_800  # 2100-01-01 00:00:00 UTC
  TIMESTAMP_PROPERTY_REGEX = /(_at|date|datetime|timestamp|created|updated|expires)/i

  # Day-first (French/EU) formats take precedence; month-first (US) formats are
  # only tried when the day-first interpretation is impossible (e.g. 12/25/2023).
  DATE_FORMATS = [
    [/\A\d{4}-\d{1,2}-\d{1,2}\z/, ['%Y-%m-%d']],
    [%r{\A\d{4}/\d{1,2}/\d{1,2}\z}, ['%Y/%m/%d']],
    [%r{\A\d{1,2}/\d{1,2}/\d{4}\z}, ['%d/%m/%Y', '%m/%d/%Y']],
    [/\A\d{1,2}-\d{1,2}-\d{4}\z/, ['%d-%m-%Y', '%m-%d-%Y']],
    [/\A\d{1,2}\.\d{1,2}\.\d{4}\z/, ['%d.%m.%Y', '%m.%d.%Y']],
  ].freeze

  DATETIME_REGEXP = /\A(?<date>\S+)\s+(?<time>\d{1,2}:\d{2}(?::\d{2})?)\z/

  def self.should_suggest_timestamp_mapping?(value, property_name)
    return false unless property_name.to_s.match?(TIMESTAMP_PROPERTY_REGEX)

    value = convert_unix_timestamp(value)
    Integer(value).between?(TIMESTAMP_MIN, TIMESTAMP_MAX)
  rescue
    false
  end

  def self.likely_string_timestamp?(value)
    value.to_s.strip.match?(TIMESTAMP_STRING_REGEXP)
  end

  def self.convert_unix_timestamp(value)
    return nil if !likely_string_timestamp?(value)
    value.to_s.to_i
  end

  def self.parsable_iso8601_date?(value)
    parse_date(value).present?
  end

  def self.convert_to_iso8601_date(value)
    parse_date(value)&.iso8601
  end

  def self.parsable_iso8601_datetime?(value)
    convert_to_iso8601_datetime(value).present?
  end

  def self.convert_to_iso8601_datetime(value)
    if (value =~ /=>/).present?
      begin
        hash_date = YAML.safe_load(value.gsub('=>', ': '))
        year, month, day, hour, minute = hash_date.values_at(1, 2, 3, 4, 5)
        Time.zone.local(year, month, day, hour, minute).iso8601
      rescue
        nil
      end
    elsif (match = DATETIME_REGEXP.match(value.to_s.strip)) && (date = parse_date(match[:date]))
      Time.zone.parse("#{date.iso8601} #{match[:time]}").iso8601
    elsif (date = parse_date(value))
      date.in_time_zone.iso8601
    else
      Time.zone.iso8601(value).iso8601 # ensure it is a valid ISO8601 datetime
    end
  rescue
    nil
  end

  def self.parse_date(value)
    normalized = value.to_s.strip
    _, formats = DATE_FORMATS.find { |regexp, _| regexp.match?(normalized) }
    return nil if formats.nil?

    formats.each do |format|
      return Date.strptime(normalized, format)
    rescue Date::Error
      next
    end
    nil
  end
  private_class_method :parse_date
end
