# frozen_string_literal: true

module ChampValidateConcern
  extend ActiveSupport::Concern

  included do
    validates_with ExternalDataChampValidator, if: :validate_external_data_response?
    validate :validate_completed, on: :champ_completeness, if: :visible?
  end

  # Overridden by champs with multi-input completeness rules (address, linked drop down)
  def validate_completed
    errors.add(:value, :missing) if mandatory_blank?
  end

  private

  def should_validate_in_current_context?
    # validation_context is an array when champs are validated for completeness
    # ([:champ_value, :champ_completeness])
    Array(validation_context).include?(:champ_value) && visible?
  end

  def validate_external_data_response?
    should_validate_in_current_context? && has_async_external_data? && external_data_needed_for_validation?
  end
end
