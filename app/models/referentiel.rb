# frozen_string_literal: true

class Referentiel < ApplicationRecord
  has_many :items, -> { order(:id) }, class_name: 'ReferentielItem', dependent: :destroy, inverse_of: :referentiel
  has_many :types_de_champ, inverse_of: :referentiel, dependent: :nullify

  # only an API referentiel can serve the autocompletion
  def autocomplete_ready?
    false
  end

  def headers_with_path
    headers.map { [_1, self.class.header_to_path(_1)] }
  end

  def drop_down_options
    path = self.class.header_to_path(headers.first)
    items.filter_map { _1.value(path) }
  end

  def options_for_select
    path = self.class.header_to_path(headers.first)
    items.filter_map do |item|
      value = item.value(path)
      [value, item.id.to_s] if value.present?
    end
  end

  def options_for_path(path)
    value_path = self.class.header_to_path(headers.first)
    items.to_set { _1.value(path) if _1.value(value_path).present? }.compact.sort.map { [_1, _1] }
  end

  # Resolves a prefill input — either an item id or a first-column label — to
  # the item id a drop_down champ stores, or nil when it matches no item.
  # Owner of the id-or-label logic so the prefill screening can share it.
  def resolve_item_id(input)
    return if input.blank?
    item = items.find_by(id: input) || item_by_label(input)
    item&.id&.to_s
  end

  def self.header_to_path(header)
    header.to_s.parameterize.underscore
  end

  private

  def item_by_label(label)
    path = self.class.header_to_path(headers.first)
    items.find { _1.value(path) == label }
  end
end
