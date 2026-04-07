# frozen_string_literal: true

class Champs::FranceConnectBadgeComponent < ApplicationComponent
  def initialize(champ:)
    @champ = champ
  end

  def render?
    @champ.data.is_a?(Hash) && @champ.data["prefilled_from_fc"]
  end

  def call
    tag.p(class: "fr-tag fr-tag--sm fr-mt-1w") { t('.label') }
  end
end
