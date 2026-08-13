# frozen_string_literal: true

class TypesDeChamp::CheckboxTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def self.category = CHOICE

  def typed_champ_value(champ)
    champ_value_true?(champ) ? 'Oui' : 'Non'
  end

  def typed_champ_value_for_export(champ, path = :value)
    champ_value_true?(champ) ? 'on' : 'off'
  end

  def typed_champ_value_for_api(champ, version: 2)
    case version
    when 2
      champ_value_true?(champ).to_s
    else
      super
    end
  end

  def champ_default_value
    'Non'
  end

  def champ_default_export_value(path = :value)
    'off'
  end

  def champ_default_api_value(version = 2)
    case version
    when 2
      'false'
    else
      nil
    end
  end

  def typed_champ_blank_or_invalid?(champ) = !champ_value_true?(champ)

  private

  def champ_value_true?(champ) = champ.value == 'true'
end
