# frozen_string_literal: true

class Dossiers::DatePrefilledFromFranceConnectComponent < ApplicationComponent
  def initialize(champ:)
    @champ = champ
  end

  def render?
    @champ.prefilled_from_france_connect_information?
  end

  def call
    render(Dossiers::ExternalDataCardComponent.new(source: "FranceConnect")) do
      helpers.tag.p(@champ.to_s, class: "copy-zone fr-mb-0")
    end
  end
end
