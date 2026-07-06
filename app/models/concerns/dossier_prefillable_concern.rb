# frozen_string_literal: true

module DossierPrefillableConcern
  extend ActiveSupport::Concern

  def prefill!(champs_with_attributes, identity_attributes)
    return if champs_with_attributes.empty? && identity_attributes.empty?

    transaction do
      champs_with_attributes.each do |champ, attributes|
        champ.assign_attributes(attributes.merge(prefilled: true))
        champ.save!(validate: false)
      end

      assign_attributes(prefilled: true)
      assign_attributes(individual_attributes: identity_attributes) if identity_attributes.present?
      save!(validate: false)
    end

    enqueue_fetch_external_data_jobs(champs_with_attributes.map(&:first))
  end
end
