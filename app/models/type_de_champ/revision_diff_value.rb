# frozen_string_literal: true

# A value of TypeDeChamp#revision_diff_attributes that is compared on one
# thing but reported as another: an attachment compared by checksum but
# reported by filename, a condition compared as a Logic tree but reported as
# its human-readable form, etc. The report value is computed lazily, only for
# attributes that actually changed.
class TypeDeChamp::RevisionDiffValue
  attr_reader :key

  def self.key_of(value) = value.is_a?(self) ? value.key : value
  def self.report_of(value) = value.is_a?(self) ? value.report : value

  def initialize(key, &report)
    @key = key
    @report = report
  end

  def report = @report ? @report.call : key
end
