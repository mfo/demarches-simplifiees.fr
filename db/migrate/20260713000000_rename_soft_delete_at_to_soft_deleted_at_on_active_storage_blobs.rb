# frozen_string_literal: true

class RenameSoftDeleteAtToSoftDeletedAtOnActiveStorageBlobs < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      rename_column :active_storage_blobs, :soft_delete_at, :soft_deleted_at
    end
  end
end
