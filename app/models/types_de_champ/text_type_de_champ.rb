# frozen_string_literal: true

class TypesDeChamp::TextTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def prefillable? = true

  def typed_champ_value_for_export(champ, path = :value)
    Sanitizers::Xml.sanitize(champ_text_value(champ))
  end
end
