# frozen_string_literal: true

class TypesDeChamp::COJOTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def typed_champ_value(champ)
    "#{champ.accreditation_number} – #{champ.accreditation_birthdate}"
  end

  def typed_champ_blank?(champ) = champ.accreditation_success != true
end
