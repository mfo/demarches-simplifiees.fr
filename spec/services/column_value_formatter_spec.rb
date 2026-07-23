# frozen_string_literal: true

require "rails_helper"

RSpec.describe ColumnValueFormatter do
  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :text, libelle: 'Ville' }, { type: :date, libelle: 'Date' }]) }
  let(:text_column) { procedure.columns.find { |c| c.respond_to?(:tdc_type) && c.tdc_type == 'text' } }
  let(:date_column) { procedure.columns.find { |c| c.respond_to?(:tdc_type) && c.tdc_type == 'date' } }

  it 'formats a date with the short format' do
    expect(described_class.format(column: date_column, raw_value: Date.new(2026, 3, 18))).to eq(I18n.l(Date.new(2026, 3, 18), format: :short))
  end

  it 'escapes and returns text values' do
    expect(described_class.format(column: text_column, raw_value: 'Presse Océan')).to eq('Presse Océan')
  end

  it 'returns nil when raw_value is nil' do
    expect(described_class.format(column: text_column, raw_value: nil)).to be_nil
  end

  describe 'format_enums' do
    let(:enums_column) { double('column', type: :enums) }

    it 'returns an html_safe SafeBuffer and escapes HTML chars in labels' do
      allow(enums_column).to receive(:label_for_value).with('a').and_return('A & B')
      allow(enums_column).to receive(:label_for_value).with('b').and_return('C')

      result = described_class.format(column: enums_column, raw_value: ['a', 'b'])

      expect(result).to be_html_safe
      expect(result).to include('A &amp; B')
      expect(result).to include('C')
    end
  end
end
