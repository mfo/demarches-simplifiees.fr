# frozen_string_literal: true

class AddEstimatedProcessingDurationVisibleToProcedures < ActiveRecord::Migration[7.2]
  def change
    add_column :procedures, :estimated_processing_duration_visible, :boolean, default: true, null: false
  end
end
