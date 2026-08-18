# frozen_string_literal: true

class TypesDeChamp::DatetimeTypeDeChamp < TypeDeChamp
  def self.editable_option_keys = [:date_in_past, :start_date, :end_date, :range_date]
  def self.column_type = :datetime

  def prefillable? = true
  def customizable? = true

  def typed_champ_value(champ)
    I18n.l(Time.zone.parse(champ.value))
  end
end
