# frozen_string_literal: true

class Instructeurs::InstructionButtonComponent < ApplicationComponent
  attr_reader :dossier, :batch, :procedure

  def initialize(dossier: nil, batch: false, procedure:)
    @dossier = dossier
    @batch = batch
    @procedure = procedure
  end

  def render?
    return true if batch
    dossier&.en_instruction?
  end
end
