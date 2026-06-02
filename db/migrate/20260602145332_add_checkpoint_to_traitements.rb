# frozen_string_literal: true

class AddCheckpointToTraitements < ActiveRecord::Migration[7.2]
  def change
    add_column :traitements, :checkpoint, :string, null: true
  end
end
