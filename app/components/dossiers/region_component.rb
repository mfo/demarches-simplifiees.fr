# frozen_string_literal: true

class Dossiers::RegionComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    render Dossiers::ExternalChampComponent.new(data:, source:)
  end

  private

  def data
    [[t(".region_label"), champ.name], [t(".insee_code_label"), champ.code]]
  end

  def source = t(".source")
end
