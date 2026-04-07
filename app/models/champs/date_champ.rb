# frozen_string_literal: true

class Champs::DateChamp < Champ
  attr_accessor :prefilled_from_france_connect

  validates_with DateLimitValidator, if: :should_validate_in_current_context?
  before_validation :convert_to_iso8601_date, unless: -> { validation_context == :prefill }
  before_save :clear_prefilled_from_fc_flag_if_modified
  validate :iso_8601

  def search_terms
    # Text search is pretty useless for dates so we’re not including these champs
  end

  private

  def clear_prefilled_from_fc_flag_if_modified
    return if prefilled_from_france_connect
    return if !value_changed?
    return if data.blank?

    data.delete("prefilled_from_fc")
  end

  def convert_to_iso8601_date
    self.value = DateDetectionUtils.convert_to_iso8601_date(value)
  end

  def iso_8601
    return if DateDetectionUtils.parsable_iso8601_date?(value) || value.blank?

    # i18n-tasks-use t('errors.messages.not_a_date')
    errors.add :date, :not_a_date
  end
end
