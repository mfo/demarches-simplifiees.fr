# frozen_string_literal: true

class RemoveChampsStableIdIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    remove_index :champs, name: :index_champs_on_stable_id, algorithm: :concurrently
  end
end
