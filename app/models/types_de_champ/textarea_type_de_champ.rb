# frozen_string_literal: true

class TypesDeChamp::TextareaTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def self.editable_option_keys = [:character_limit]

  def customizable? = false

  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def typed_champ_value_for_export(champ, path = :value)
    Sanitizers::Xml.sanitize(champ_text_value(champ))
  end
end
