# frozen_string_literal: true

class Users::DossierCardChampsComponent < ApplicationComponent
  Line = Data.define(:label, :value)

  def initialize(columns:, champs_by_stable_id:)
    @columns = columns
    @champs_by_stable_id = champs_by_stable_id
  end

  def render? = lines.any?

  private

  attr_reader :columns, :champs_by_stable_id

  def lines
    @lines ||= columns.filter_map do |column|
      next unless column.champ_column?

      champ = champs_by_stable_id[column.stable_id]
      raw = column.value(champ)
      formatted = ColumnValueFormatter.format(column:, raw_value: raw)
      next if formatted.blank?

      Line.new(label: column.label, value: formatted)
    end
  end
end
