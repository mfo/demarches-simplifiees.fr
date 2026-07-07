# frozen_string_literal: true

class Instructeurs::EnvoyerDossierFormComponent < ApplicationComponent
  attr_reader :dossier, :potential_recipients

  def initialize(dossier:, potential_recipients:)
    @dossier = dossier
    @potential_recipients = potential_recipients
  end

  private

  def recipient_items
    potential_recipients.map { [it.email, it.id] }
  end
end
