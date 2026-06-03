# frozen_string_literal: true

class Columns::AddressColumn < Columns::ChampColumn
  private

  # The raw `value` column is not guaranteed to match the canonical address
  # label stored in `value_json` (eg. BAN addresses). The PDF, the UI and the
  # API all display `address_label`, so exports and dossiers lists must too.
  # Fallback to the raw value for champs of another type (eg. after a rebase).
  def string_value(champ) = champ.respond_to?(:address_label) ? champ.address_label : super
end
