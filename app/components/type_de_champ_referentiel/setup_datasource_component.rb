# frozen_string_literal: true

class TypeDeChampReferentiel::SetupDatasourceComponent < ApplicationComponent
  attr_reader :type_de_champ, :procedure
  def initialize(type_de_champ:, procedure:)
    @type_de_champ = type_de_champ
    @procedure = procedure
  end

  def id
    dom_id(type_de_champ, :setup_datasource)
  end

  def form_options
    { id:, method: :patch, data: { turbo: 'true' }, html: { novalidate: 'novalidate' } }
  end

  def adatper?(value)
    type_de_champ.referentiel_adapter == value
  end

  def submit_options
    if adatper?(nil)
      { class: 'fr-btn', disabled: true }
    else
      { class: 'fr-btn' }
    end
  end

  private

  def force_autosubmit? = adatper?(nil)
end
