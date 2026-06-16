# frozen_string_literal: true

class ExternalDataChampValidator < ActiveModel::Validator
  # Required checks are delegated to check_mandatory_and_visible_champs_public.
  def validate(record)
    if record.pending?
      # User filled the field, but background job is still running.
      record.errors.add(:external_id, :api_response_pending)
    elsif record.external_error?
      # User filled the field, but background job failed.
      record.errors.add(:external_id, error_key_for_api_response_code(record))
    end
  end

  private

  def error_key_for_api_response_code(record)
    first_exception = record.fetch_external_data_exceptions&.first
    return :code_unknown if first_exception.nil?

    http_status = first_exception.code
    error_key = :"code_#{http_status}"

    if http_status && translation_exists_for?(error_key, record)
      error_key
    else
      :api_response_error
    end
  end

  def translation_exists_for?(error_key, record)
    model_key = record.class.model_name.i18n_key

    I18n.exists?("activerecord.errors.models.#{model_key}.attributes.value.#{error_key}") ||
      I18n.exists?("activerecord.errors.messages.#{error_key}")
  end
end
