# frozen_string_literal: true

class AddCheckpointToChamps < ActiveRecord::Migration[7.2]
  def change
    add_column :champs, :checkpoint, :string, null: true
  end
end
