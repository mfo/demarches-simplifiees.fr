# frozen_string_literal: true

class DossiersListPersonnalisation < ApplicationRecord
  belongs_to :user
  belongs_to :procedure

  attribute :displayed_columns, :personnalisation_column, array: true

  def displayed_columns = super.compact
end
