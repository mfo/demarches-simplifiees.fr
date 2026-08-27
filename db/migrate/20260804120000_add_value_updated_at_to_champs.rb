# frozen_string_literal: true

class AddValueUpdatedAtToChamps < ActiveRecord::Migration[8.0]
  def change
    add_column :champs, :value_updated_at, :datetime
  end
end
