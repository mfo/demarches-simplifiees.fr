# frozen_string_literal: true

class Dossiers::ShortIdentiteEntrepriseComponentPreview < ViewComponent::Preview
  include Dossiers::FakeEtablissementConcern

  def default
    render Dossiers::ShortIdentiteEntrepriseComponent.new(etablissement:)
  end

  def degraded_mode
    et = Etablissement.new(siret: "11004601800013")
    et.define_singleton_method(:as_degraded_mode?) { true }
    render Dossiers::ShortIdentiteEntrepriseComponent.new(etablissement: et)
  end

  def non_diffusable
    et = etablissement
    et.diffusable_commercialement = false
    render Dossiers::ShortIdentiteEntrepriseComponent.new(etablissement: et)
  end
end
