# frozen_string_literal: true

class AddIndexOnNotificationTypeAndDossierIdToDossierNotifications < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :dossier_notifications,
              [:notification_type, :dossier_id],
              name: 'index_dossier_notifications_on_type_and_dossier_id',
              algorithm: :concurrently
  end
end
