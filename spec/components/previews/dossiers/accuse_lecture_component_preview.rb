# frozen_string_literal: true

class Dossiers::AccuseLectureComponentPreview < ViewComponent::Preview
  def default
    dossier = Dossier.joins(:procedure).where(procedures: { accuse_lecture: true }, state: :accepte).first
    dossier ||= Dossier.where(state: :accepte).first
    render Dossiers::AccuseLectureComponent.new(dossier:)
  end
end
