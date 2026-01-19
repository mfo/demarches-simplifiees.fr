# frozen_string_literal: true

class Instructeurs::EditDossierConfirmComponent < ApplicationComponent
  def initialize(dossier:)
    @dossier = dossier
  end

  def title
    t('.title', dossier_number: @dossier.id, demandeur: helpers.demandeur_dossier(@dossier))
  end

  def default_message
    Message::DossierModifierParInstructeurComponent.preview(@dossier)
  end

  def render?
    @dossier.instructeur_buffer_changes?
  end
end
