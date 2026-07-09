# frozen_string_literal: true

class NumberFormatValidator < ActiveModel::Validator
  INTEGER_FORMAT = /\A[+-]?\d+\z/
  DECIMAL_FORMAT = /\A-?[0-9]+(\.[0-9]{1,3})?\z/

  # Pure functions of (value, decimal:) so prefill screening can share
  # the normalization and format logic with the AR validation. violations
  # expects an already normalized value and returns [error_key, details] pairs.
  def self.normalize(value, decimal: false)
    return value if value.blank?

    formatted = value.to_s.gsub(/[[:space:]]/, "")
    decimal ? formatted.tr(",", ".") : formatted
  end

  def self.violations(value, decimal: false)
    return [] if value.blank?

    decimal ? decimal_violations(value) : integer_violations(value)
  end

  def validate(champ)
    self.class.violations(champ.value, decimal: champ.decimal_number?).each do |error, details|
      champ.errors.add(:value, error, **details)
    end
  end

  class << self
    private

    def integer_violations(value)
      if value.match?(INTEGER_FORMAT)
        []
      else
        # i18n-tasks-use t('errors.messages.not_an_integer')
        [[:not_an_integer, {}]]
      end
    end

    def decimal_violations(value)
      violations = []
      violations << [:not_a_number, {}] if Float(value, exception: false).nil?
      # i18n-tasks-use t('errors.messages.not_a_float')
      violations << [:not_a_float, {}] if !value.match?(DECIMAL_FORMAT)
      violations
    end
  end
end
