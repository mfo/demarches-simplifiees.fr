# frozen_string_literal: true

class DropDownOptionsValidator < ActiveModel::Validator
  # Pure function of (values, type_de_champ) so prefill screening can share
  # the options inclusion check with the AR validation. Simple drop-downs
  # accept the configured options; advanced (referentiel-backed) ones accept
  # the given referentiel_keys instead. Returns [error_key, details] pairs.
  def self.violations(values, type_de_champ, referentiel_keys: [])
    values = values.compact_blank
    return [] if values.empty?

    allowed = type_de_champ.drop_down_advanced? ? referentiel_keys : type_de_champ.drop_down_options
    if (values - allowed).empty?
      []
    else
      [[:not_in_options, {}]]
    end
  end

  # The instance validator targets Champs::MultipleDropDownListChamp, whose
  # advanced mode accepts the referentiel items stored on the champ.
  def validate(champ)
    self.class.violations(champ.selected_options, champ.type_de_champ, referentiel_keys: champ.referentiels&.keys || []).each do |error, details|
      champ.errors.add(:value, error, **details)
    end
  end
end
