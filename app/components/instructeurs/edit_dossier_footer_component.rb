# frozen_string_literal: true

class Instructeurs::EditDossierFooterComponent < ApplicationComponent
  def initialize(dossier:)
    @dossier = dossier
  end
end
