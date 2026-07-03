# frozen_string_literal: true

module DossierValidateConcern
  extend ActiveSupport::Concern

  included do
    validate :validate_champs_public_value, on: :champs_public_value
    validate :validate_champs_private_value, on: :champs_private_value
  end

  def champs_public_valid?
    validate(:champs_public_value)
    check_mandatory_and_visible_champs_for(project_champs_public)
    errors.blank?
  end

  def champs_private_valid?
    validate(:champs_private_value)
    check_mandatory_and_visible_champs_for(project_champs_private)
    errors.blank?
  end

  private

  def validate_champs_public_value
    validate_projected_champs(project_champs_public_all)
  end

  def validate_champs_private_value
    validate_projected_champs(project_champs_private_all)
  end

  def validate_projected_champs(champs)
    champs.each do |champ|
      next if champ.validate(:champ_value)
      champ.errors.each { errors.import(it) }
    end
  end

  def check_mandatory_and_visible_champs_for(collection)
    collection.filter(&:visible?).each do |champ|
      if champ.mandatory_blank? && !champ.respond_to?(:validate_completed)
        error = champ.errors.add(:value, :missing)
        errors.import(error)
      end

      if champ.repetition?
        champ.rows.each do |champs|
          champs.filter(&:visible?).each do |champ|
            if champ.respond_to?(:validate_completed)
              champ.validate_completed
              champ.errors.each { errors.import(it) }
            elsif champ.mandatory_blank?
              error = champ.errors.add(:value, :missing)
              errors.import(error)
            end
          end
        end
      elsif champ.respond_to?(:validate_completed)
        champ.validate_completed
        champ.errors.each { errors.import(it) }
      end
    end
    errors
  end
end
