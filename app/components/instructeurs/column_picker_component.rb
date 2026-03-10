# frozen_string_literal: true

class Instructeurs::ColumnPickerComponent < ApplicationComponent
  attr_reader :procedure, :procedure_presentation, :instructeur

  def initialize(procedure:, procedure_presentation:, instructeur:)
    @procedure = procedure
    @procedure_presentation = procedure_presentation
    @instructeur = instructeur
    @displayable_columns_for_select, @displayable_columns_selected = displayable_columns_for_select
  end

  def displayable_columns_for_select
    [
      procedure.columns.filter(&:displayable).map { |column| [column.label, column.id] },
      procedure_presentation.displayed_columns.map(&:id),
    ]
  end

  def instructeur_is_admin?
    admin = instructeur.user.administrateur
    admin.present? && admin.owns?(procedure)
  end
end
