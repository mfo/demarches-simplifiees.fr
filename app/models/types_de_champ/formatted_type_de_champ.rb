# frozen_string_literal: true

class TypesDeChamp::FormattedTypeDeChamp < TypesDeChamp::TypeDeChampBase
  after_initialize :set_default_options

  def self.editable_option_keys
    [
      :formatted_mode, :numbers_accepted, :letters_accepted, :special_characters_accepted,
      :min_character_length, :max_character_length,
      :expression_reguliere, :expression_reguliere_indications, :expression_reguliere_exemple_text, :expression_reguliere_error_message,
    ]
  end

  def typed_champ_value_for_export(champ, path = :value)
    Sanitizers::Xml.sanitize(champ_text_value(champ))
  end

  private

  def set_default_options
    if options&.empty?
      self.options = { formatted_mode: 'simple', letters_accepted: true, numbers_accepted: true, special_characters_accepted: true }
    end
  end
end
