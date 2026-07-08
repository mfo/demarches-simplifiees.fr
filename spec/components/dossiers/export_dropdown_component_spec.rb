# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dossiers::ExportDropdownComponent, type: :component do
  let(:procedure) { create(:procedure) }
  let(:export_url) { double() }
  before(:each) { allow(export_url).to receive(:call).and_return('http://example.com/export') }

  describe '#include_archived_title' do
    context 'when archived_count is greater than 1' do
      it 'returns the pluralized archived title' do
        component = described_class.new(procedure:, archived_count: 3, statut: 'tous', export_url:)
        allow(component).to receive(:params).and_return({ procedure_id: procedure.id })
        render_inline(component)
        expect(component.include_archived_title).to eq("<span>Inclure les <strong>3 dossiers « à archiver »</strong></span>")
      end
    end

    context 'when archived_count is 1 or less' do
      it 'returns the singular archived title' do
        component = described_class.new(procedure:, archived_count: 1, statut: 'tous', export_url:)
        allow(component).to receive(:params).and_return({ procedure_id: procedure.id })
        render_inline(component)
        expect(component.include_archived_title).to eq("<span>Inclure le <strong>dossier « à archiver »</strong></span>")
      end
    end
  end
end
