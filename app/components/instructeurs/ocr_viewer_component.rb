# frozen_string_literal: true

class Instructeurs::OCRViewerComponent < ApplicationComponent
  attr_reader :champ, :value_json

  def initialize(champ:)
    @champ, @value_json = champ, champ.value_json
  end

  def formated_data
    {
      account_holder: value_json.dig('rib', 'account_holder')&.split("\n")&.join('<br>'),
      iban: value_json.dig('rib', 'iban'),
      bic: value_json.dig('rib', 'bic'),
      bank_name: value_json.dig('rib', 'bank_name'),
    }
  end

  def render?
    champ.RIB? && champ.fetched?
  end
end
