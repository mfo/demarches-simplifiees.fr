# frozen_string_literal: true

class AddProConnectRequiredAtToAdministrateurs < ActiveRecord::Migration[8.0]
  def change
    add_column :administrateurs, :pro_connect_required_at, :datetime
  end
end
