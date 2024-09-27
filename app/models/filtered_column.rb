# frozen_string_literal: true

class FilteredColumn
  def initialize(column:, filter:)
    @column = column
    @filter = filter
  end
end
