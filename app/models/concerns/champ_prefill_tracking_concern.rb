# frozen_string_literal: true

module ChampPrefillTrackingConcern
  extend ActiveSupport::Concern

  def prefilled_value_modified?
    prefilled? &&
      prefilled_original_value.present? &&
      !prefilled_value_matches_current?
  end

  def prefilled_value_matches_current?
    return false if prefilled_original_value.blank?

    if prefilled_original_value.key?("external_id")
      external_id.to_s == prefilled_original_value["external_id"].to_s
    elsif prefilled_original_value.key?("value")
      value.to_s == prefilled_original_value["value"].to_s
    else
      false
    end
  end

  def revert_to_prefilled_value!
    update!(prefilled_original_value)
  end
end
