# frozen_string_literal: true

class AddMessageErrorToDossierBatchOperations < ActiveRecord::Migration[7.2]
  def change
    add_column :dossier_batch_operations, :error_message, :string
  end
end
