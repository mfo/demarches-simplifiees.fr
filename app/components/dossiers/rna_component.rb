# frozen_string_literal: true

class Dossiers::RNAComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    if champ.fetched?
      render Dossiers::ExternalChampComponent.new(data:, details:, source:)
    elsif champ.pending?
      tag.p(t('shared.champs.external_data.pending', identifier: champ.external_id), class: "fr-mt-1w")
    end
  end

  private

  def data
    [
      [champ.class.human_attribute_name(:value), champ.to_s],
      *['titre', 'objet'].map { label_value(it) },
    ]
  end

  def details
    [
      *['date_creation', 'date_declaration', 'date_publication'].map { label_value(it) },
      *helpers.address_array(champ),
    ]
  end

  def label_value(key)
    [champ.class.human_attribute_name("association_#{key}"), champ.data["association_#{key}"]]
  end

  def source
    tag.acronym("RNA", title: "Répertoire National des Associations")
  end
end
