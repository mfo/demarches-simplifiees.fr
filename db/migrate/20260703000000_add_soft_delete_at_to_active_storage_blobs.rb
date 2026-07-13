# frozen_string_literal: true

class AddSoftDeleteAtToActiveStorageBlobs < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :active_storage_blobs, :soft_delete_at, :datetime, null: true, if_not_exists: true

    add_index :active_storage_blobs, :soft_delete_at,
              where: "soft_delete_at IS NOT NULL",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
