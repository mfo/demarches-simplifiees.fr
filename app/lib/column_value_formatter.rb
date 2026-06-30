# frozen_string_literal: true

module ColumnValueFormatter
  module_function

  def format(column:, raw_value:)
    return if raw_value.nil?

    case column.type
    when :boolean
      if column.type_de_champ? && column.tdc_type == 'checkbox'
        raw_value ? I18n.t('activerecord.attributes.type_de_champ.type_champs.checkbox_true') : ''
      else
        raw_value ? I18n.t('utils.yes') : I18n.t('utils.no')
      end
    when :attachments
      raw_value.present? ? 'présent' : 'absent'
    when :enum
      format_enum(column:, raw_value:)
    when :enums
      format_enums(column:, raw_values: raw_value)
    when :date
      raw_value = Date.parse(raw_value) if raw_value.is_a?(String)
      I18n.l(raw_value, format: :short)
    when :datetime
      raw_value = DateTime.parse(raw_value) if raw_value.is_a?(String)
      I18n.l(raw_value, format: :short_with_time)
    else
      raw_value.html_safe? ? raw_value : ERB::Util.html_escape(raw_value.to_s)
    end
  end

  def format_enums(column:, raw_values:)
    ActionController::Base.helpers.safe_join(
      raw_values.map { |v| format_enum(column:, raw_value: v) },
      ', '
    )
  end

  def format_enum(column:, raw_value:)
    column.label_for_value(raw_value)
  end
end
