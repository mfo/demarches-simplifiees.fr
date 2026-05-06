# frozen_string_literal: true

class AddPartialIndexOnBlobsPendingVirusScan < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :active_storage_blobs,
              [:virus_scan_result, :id],
              name: "index_active_storage_blobs_on_pending_virus_scan",
              order: { id: :desc },
              algorithm: :concurrently,
              if_not_exists: true
  end
end
