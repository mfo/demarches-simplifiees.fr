# frozen_string_literal: true

class TypesDeChamp::DateTypeDeChamp < TypeDeChamp
  def self.editable_option_keys = [:birthdate, :prefill_with_france_connect_information, :date_in_past, :start_date, :end_date, :range_date]
  def self.column_type = :date

  def prefillable? = true

  def typed_champ_value(champ)
    I18n.l(Time.zone.parse(champ.value).to_date, format: :long)
  rescue ArgumentError
    champ.value.presence || "" # old dossiers can have not parseable dates
  end
end
