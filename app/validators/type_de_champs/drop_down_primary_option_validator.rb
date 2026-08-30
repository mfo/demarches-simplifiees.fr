# frozen_string_literal: true

class TypeDeChamps::DropDownPrimaryOptionValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, types_de_champ)
    types_de_champ
      .filter(&:linked_drop_down_list?)
      .each { validate_starts_with_primary_option(procedure, attribute, it) }
  end

  private

  def validate_starts_with_primary_option(procedure, attribute, drop_down)
    options = drop_down.drop_down_options
    # an empty menu is already reported by NoEmptyDropDownValidator
    return if options.blank?
    return if TypesDeChamp::LinkedDropDownListTypeDeChamp::PRIMARY_PATTERN.match?(options.first)

    procedure.errors.add(
      attribute,
      procedure.errors.generate_message(attribute, :missing_primary_option, { value: drop_down.libelle }),
      type_de_champ: drop_down
    )
  end
end
