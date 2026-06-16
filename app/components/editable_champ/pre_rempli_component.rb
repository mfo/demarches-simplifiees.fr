# frozen_string_literal: true

class EditableChamp::PreRempliComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_champ_container
    :div
  end

  def dsfr_input_classname
    'fr-input'
  end
end
