# frozen_string_literal: true

module ChampValidateConcern
  extend ActiveSupport::Concern

  included do
    validates_with ExternalDataChampValidator, if: :validate_external_data_response?
  end

  private

  def should_validate_in_current_context?
    case validation_context
    when :champ_value
      visible?
    when :prefill
      true
    else
      false
    end
  end

  def validate_external_data_response?
    should_validate_in_current_context? && has_async_external_data? && external_data_needed_for_validation?
  end
end
