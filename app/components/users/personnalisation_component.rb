# frozen_string_literal: true

class Users::PersonnalisationComponent < ApplicationComponent
  def initialize(procedure:, personnalisation:)
    @procedure = procedure
    @personnalisation = personnalisation
  end

  private

  attr_reader :procedure, :personnalisation

  def select_options
    groups = procedure.customizable_columns_by_section

    if groups.size == 1 && groups.first.first.nil?
      { items: items_for(groups.first.last) }
    else
      sections = groups.map do |stable_id, section_label, columns|
        {
          id: stable_id&.to_s || 'default',
          label: section_label || t('.default_section'),
          items: items_for(columns),
        }
      end
      { sections: }
    end
  end

  def items_for(columns)
    columns.map { { label: _1.label, value: _1.id, mandatory: _1.mandatory } }
  end

  def selected_value
    (personnalisation&.displayed_columns || []).map(&:id)
  end

  def field_name
    "personnalisations[#{procedure.id}][displayed_columns][]"
  end
end
