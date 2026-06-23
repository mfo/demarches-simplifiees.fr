# frozen_string_literal: true

class Dossiers::RNFComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    if champ.external_id.blank?
      tag.p(t('not_filled', scope: 'activerecord.attributes.type_de_champ'), class: "fr-mt-1w")
    elsif champ.fetched?
      render Dossiers::ExternalChampComponent.new(data:, details:, source:)
    elsif champ.pending?
      tag.p(t('shared.champs.external_data.pending', identifier: champ.value), class: "fr-mt-1w")
    elsif champ.external_data_not_found?
      tag.p(t('shared.champs.external_data.not_found', identifier: champ.value), class: "fr-mt-1w")
    elsif champ.external_error?
      tag.p(t('shared.champs.external_data.error', identifier: champ.value), class: "fr-mt-1w")
    end
  end

  private

  def data
    [
      [label(:rnf_id), champ.to_s],
      *['title', 'email'].map { [label(it), champ.data[it]] },
    ]
  end

  def details
    [
      *['phone', 'status'].map { [label(it), champ.data[it]] },
      *['createdAt', 'updatedAt', 'dissolvedAt'].map { [label(it), champ.data[it]&.to_date] },
      *helpers.address_array(champ),
    ]
  end

  def label(key) = champ.class.human_attribute_name(key)

  def source
    tag.acronym("RNF", title: "Répertoire National des Fondations")
  end
end
