# frozen_string_literal: true

class AddSubmittedWithProConnectToDossiers < ActiveRecord::Migration[7.2]
  def change
    add_column :dossiers, :submitted_with_pro_connect, :boolean, default: false, null: false
  end
end
