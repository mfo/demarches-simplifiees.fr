# frozen_string_literal: true

class TypesDeChamp::PrefillDropDownListTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def all_possible_values
    if drop_down_other?
      [I18n.t("views.prefill_descriptions.edit.possible_values.drop_down_list_other_html")] + drop_down_options
    else
      drop_down_options
    end
  end

  def example_value
    all_possible_values.first
  end

  private

  # Advanced (referentiel-backed) lists and lists accepting "other" take
  # values the options don't enumerate, so only simple lists are screened.
  def screened_value(champ, value)
    return nil if !value.is_a?(String)
    return nil if screenable? && DropDownOptionsValidator.violations([value], self).any?

    value
  end

  def screenable?
    drop_down_simple? && !drop_down_other?
  end
end
