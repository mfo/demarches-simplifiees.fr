# frozen_string_literal: true

class Dossiers::PendingCorrectionCheckboxComponentPreview < ViewComponent::Preview
  def default
    dossier = Dossier.en_construction.first
    component = Dossiers::PendingCorrectionCheckboxComponent.new(dossier:)
    component.define_singleton_method(:render?) { true }
    render(component)
  end

  def with_error
    dossier = Dossier.en_construction.first
    dossier.errors.add(:pending_correction, :blank)
    component = Dossiers::PendingCorrectionCheckboxComponent.new(dossier:)
    component.define_singleton_method(:render?) { true }
    render(component)
  end
end
