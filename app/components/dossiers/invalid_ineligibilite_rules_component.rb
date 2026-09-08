# frozen_string_literal: true

class Dossiers::InvalidIneligibiliteRulesComponent < ApplicationComponent
  def initialize(dossier:, wrapped: true)
    @dossier = dossier
    @revision = dossier.revision
    @wrapped = wrapped
  end

  private

  attr_reader :dossier

  def render?
    dossier.revision.ineligibilite_enabled?
  end

  def error_message
    dossier.revision.ineligibilite_message
  end

  # The alert only speaks about champs the usager wrote.
  def opened? = !dossier.can_submit_modifications?

  def wrapped? = @wrapped
end
