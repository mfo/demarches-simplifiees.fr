# frozen_string_literal: true

class Dossiers::ChampPrefilledBadgeComponent < ApplicationComponent
  def initialize(champ:, profile:)
    @champ = champ
    @profile = profile
  end

  def render?
    @profile != 'usager' && @champ.prefilled? && @champ.prefilled_original_value.present?
  end

  def tooltip_id
    "tooltip-prefilled-#{@champ.id}"
  end
end
