# frozen_string_literal: true

class Users::PersonnalisationComponent < ApplicationComponent
  def initialize(procedure:, personnalisation:)
    @procedure = procedure
    @personnalisation = personnalisation
  end

  private

  attr_reader :procedure, :personnalisation

  def sections
    procedure.personnalisable_columns_by_section.map do |section_label, columns|
      {
        label: section_label || t('.default_section'),
        items: columns.map { { label: _1.label, value: _1.id, mandatory: _1.mandatory } },
      }
    end
  end

  def selected_value
    (personnalisation&.displayed_columns || []).map(&:id)
  end

  def field_name
    "personnalisations[#{procedure.id}][displayed_columns][]"
  end
end
