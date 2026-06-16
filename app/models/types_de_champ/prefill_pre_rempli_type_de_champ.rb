# frozen_string_literal: true

class TypesDeChamp::PrefillPreRempliTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def all_possible_values
    drop_down_options
  end

  def example_value
    all_possible_values.first
  end
end
