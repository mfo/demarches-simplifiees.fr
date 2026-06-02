# frozen_string_literal: true

class ChangedColumn
  delegate :label, :type, :id, :stable_id, to: :@column
  attr_reader :previous_value

  def initialize(column, value, previous_value)
    @column = column
    @value = value
    @previous_value = previous_value
  end

  def value(_ = nil) = @value

  class << self
    def columns(revision, champs, reference_champs)
      row_ids = champs.values.map(&:row_id).compact.uniq.sort

      revision.types_de_champ_public.flat_map do |type_de_champ|
        if type_de_champ.repetition?
          prefix = type_de_champ.libelle
          types_de_champ = revision.children_of(type_de_champ)
          row_ids.flat_map do |row_id|
            types_de_champ.flat_map do |type_de_champ|
              public_id = type_de_champ.public_id(row_id)
              columns = type_de_champ.value_columns(procedure_id: revision.procedure_id, prefix:)
              diff_columns(columns, champs[public_id], reference_champs[public_id])
            end
          end
        else
          public_id = type_de_champ.public_id(nil)
          columns = type_de_champ.value_columns(procedure_id: revision.procedure_id)
          diff_columns(columns, champs[public_id], reference_champs[public_id])
        end
      end
    end

    private

    def diff_columns(columns, champ, reference_champ)
      return [] if champ.nil?
      columns.filter_map do |column|
        value = column.value(champ)
        previous_value = column.value(reference_champ)
        if value != previous_value
          new(column, value, previous_value)
        end
      end
    end
  end
end
