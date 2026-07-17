# frozen_string_literal: true

class AddPrefilledOriginalValueToChamps < ActiveRecord::Migration[7.2]
  def change
    add_column :champs, :prefilled_original_value, :jsonb
  end
end
