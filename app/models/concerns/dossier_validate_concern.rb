# frozen_string_literal: true

module DossierValidateConcern
  extend ActiveSupport::Concern

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

  def check_mandatory_and_visible_champs_for(collection)
    collection.filter(&:visible?).each do |champ|
      if champ.mandatory_blank? && !champ.address?
        error = champ.errors.add(:value, :missing)
        errors.import(error)
      end

      if champ.repetition?
        champ.rows.each do |champs|
          champs.filter(&:visible?).each do |champ|
            if champ.address?
              champ.validate_completed
              champ.errors.each { errors.import(it) }
            elsif champ.mandatory_blank?
              error = champ.errors.add(:value, :missing)
              errors.import(error)
            end
          end
        end
      elsif champ.address?
        champ.validate_completed
        champ.errors.each { errors.import(it) }
      end
    end
    errors
  end
end
