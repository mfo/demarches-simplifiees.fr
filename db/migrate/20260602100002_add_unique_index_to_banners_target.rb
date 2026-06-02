# frozen_string_literal: true

class AddUniqueIndexToBannersTarget < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    add_index :banners, :target, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :banners, :target
  end
end
