# frozen_string_literal: true

class TypesDeChamp::RepetitionValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, types_de_champ)
    types_de_champ.filter(&:repetition?).each do |tdc|
      validate_limits(procedure, attribute, tdc) if tdc.limit_repetitions?
    end
  end

  private

  def validate_limits(procedure, attribute, tdc)
    min_str = tdc.min_repetitions
    max_str = tdc.max_repetitions

    if min_str.blank? && max_str.blank?
      # i18n-tasks-use t('errors.messages.missing_repetition_min_or_max')
      procedure.errors.add(attribute, :missing_repetition_min_or_max, type_de_champ: tdc)
    end

    min = min_str.to_i
    max = max_str.to_i

    if tdc.mandatory?
      # min doît être nil ou > 0 car un bloc répétable obligatoire doit donc être rempli au moins une fois
      # i18n-tasks-use t('errors.messages.invalid_mandatory_repetition_min')
      procedure.errors.add(attribute, :invalid_mandatory_repetition_min, type_de_champ: tdc) if min_str.present? && min <= 0
    else
      # min doît être nil ou == 0 quand le bloc n’est pas obligatoire
      # i18n-tasks-use t('errors.messages.invalid_not_mandatory_repetition_min')
      procedure.errors.add(attribute, :invalid_not_mandatory_repetition_min, type_de_champ: tdc) if min_str.present? && min != 0
    end

    if max_str.present? && max <= 0
      # que le champ soit obligatoire ou pas, max doît être nil ou >= 1
      # i18n-tasks-use t('errors.messages.invalid_repetition_max')
      procedure.errors.add(attribute, :invalid_repetition_max, type_de_champ: tdc, min_allowed: 1)
    end

    if min_str.present? && max_str.present? && min > max
      #  que le champ soit obligatoire ou pas, min doit être <= max
      # i18n-tasks-use t('errors.messages.invalid_repetition_range')
      procedure.errors.add(attribute, :invalid_repetition_range, type_de_champ: tdc)
    end
  end
end
