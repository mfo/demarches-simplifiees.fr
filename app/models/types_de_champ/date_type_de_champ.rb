# frozen_string_literal: true

class TypesDeChamp::DateTypeDeChamp < TypeDeChamp
  def self.editable_option_keys = [:birthdate, :prefill_with_france_connect_information, :date_in_past, :start_date, :end_date, :range_date]
  def self.column_type = :date

  def prefillable? = true
  def customizable? = true

  before_save :clear_conflicting_options, if: :birthdate?
  before_save :clear_prefill_with_france_connect_information, if: -> { !birthdate? }

  def typed_champ_value(champ)
    I18n.l(Time.zone.parse(champ.value).to_date, format: :long)
  rescue ArgumentError
    champ.value.presence || "" # old dossiers can have not parseable dates
  end

  private

  def clear_conflicting_options
    self.date_in_past = nil
    self.range_date = nil
    self.start_date = nil
    self.end_date = nil
  end

  def clear_prefill_with_france_connect_information
    self.prefill_with_france_connect_information = nil
  end
end
