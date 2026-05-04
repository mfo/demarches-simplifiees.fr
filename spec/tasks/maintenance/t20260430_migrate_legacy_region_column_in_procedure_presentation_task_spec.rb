# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260430MigrateLegacyRegionColumnInProcedurePresentationTask do
    subject(:process) { described_class.process(ProcedurePresentation.find(presentation.id)) }

    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :address, libelle: 'addr' }]) }
    let(:instructeur) { create(:instructeur) }
    let(:presentation) do
      assign_to = create(:assign_to, instructeur:, groupe_instructeur: procedure.defaut_groupe_instructeur)
      assign_to.procedure_presentation_or_default_and_errors.first
    end

    let(:legacy_column) { procedure.columns.find { _1.is_a?(Columns::JSONPathColumn) && _1.jsonpath == '$.region_name' } }
    let(:new_column) { procedure.columns.find { _1.is_a?(Columns::JSONPathColumn) && _1.jsonpath == '$.region_code' } }

    def reload_displayed_column_ids
      ProcedurePresentation
        .connection
        .select_value("SELECT array_to_json(displayed_columns) FROM procedure_presentations WHERE id = #{presentation.id}")
        .then { JSON.parse(_1) }
        .map { _1['column_id'] }
    end

    def reload_filter_column_id(attr)
      ProcedurePresentation
        .connection
        .select_value("SELECT array_to_json(#{attr}) FROM procedure_presentations WHERE id = #{presentation.id}")
        .then { JSON.parse(_1) }
        .first
        &.dig('id', 'column_id')
    end

    describe '#process' do
      context 'when displayed_columns contains the legacy region column' do
        before do
          presentation.update(displayed_columns: [legacy_column])
          Current.procedure_columns = nil
        end

        it 'rewrites the column_id to point at $.region_code' do
          expect(reload_displayed_column_ids).to all(end_with('-$.region_name'))

          process

          expect(reload_displayed_column_ids).to all(end_with('-$.region_code'))
        end
      end

      context 'when an *_filters attribute contains the legacy region column' do
        before do
          presentation.update(a_suivre_filters: [FilteredColumn.new(column: legacy_column, filter: 'filter')])
          Current.procedure_columns = nil
        end

        it 'rewrites the filter column_id to point at $.region_code' do
          expect(reload_filter_column_id(:a_suivre_filters)).to end_with('-$.region_name')

          process

          expect(reload_filter_column_id(:a_suivre_filters)).to end_with('-$.region_code')
        end
      end

      context 'when displayed_columns has both the legacy and the new column' do
        before do
          presentation.update(displayed_columns: [legacy_column, new_column])
          Current.procedure_columns = nil
        end

        it 'dedupes to a single $.region_code column' do
          process

          expect(reload_displayed_column_ids.count { _1.end_with?('-$.region_code') }).to eq(1)
          expect(reload_displayed_column_ids).not_to include(end_with('-$.region_name'))
        end
      end

      context 'when displayed_columns contains an unrelated column' do
        let(:other_column) { procedure.columns.find { _1.is_a?(Columns::JSONPathColumn) && _1.jsonpath == '$.postal_code' } }

        before do
          presentation.update(displayed_columns: [other_column])
          Current.procedure_columns = nil
        end

        it 'leaves it untouched' do
          before_ids = reload_displayed_column_ids

          process

          expect(reload_displayed_column_ids).to eq(before_ids)
        end
      end

      context 'with an invalid column reference' do
        let(:invalid_column) do
          column = legacy_column
          def column.h_id
            original = super
            original[:column_id] = 'INVALID'
            original
          end
          column
        end

        before do
          presentation.update(displayed_columns: [invalid_column])
          Current.procedure_columns = nil
        end

        it 'does not raise' do
          expect { process }.not_to raise_error
        end
      end
    end
  end
end
