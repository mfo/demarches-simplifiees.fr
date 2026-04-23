# frozen_string_literal: true

class AddProConnectForMoralProcedureToProcedures < ActiveRecord::Migration[7.2]
  def change
    add_column :procedures, :pro_connect_for_moral_procedure, :boolean, default: false, null: false
  end
end
