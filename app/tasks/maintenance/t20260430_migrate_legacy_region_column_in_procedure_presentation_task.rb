# frozen_string_literal: true

# Migrate ProcedurePresentation references to the legacy `$.region_name` column
# (created before the region filter fix) over to the new `$.region_code` column.
# Once all instances are migrated, the legacy entry in AddressableColumnConcern
# can be removed.
module Maintenance
  class T20260430MigrateLegacyRegionColumnInProcedurePresentationTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    run_on_first_deploy

    LEGACY_SUFFIX = '-$.region_name'
    NEW_SUFFIX = '-$.region_code'

    def collection
      ProcedurePresentation.where(<<~SQL.squish, pattern: "%#{LEGACY_SUFFIX}%")
        displayed_columns::text LIKE :pattern
        OR a_suivre_filters::text LIKE :pattern
        OR suivis_filters::text LIKE :pattern
        OR traites_filters::text LIKE :pattern
        OR tous_filters::text LIKE :pattern
        OR supprimes_filters::text LIKE :pattern
        OR supprimes_recemment_filters::text LIKE :pattern
        OR expirant_filters::text LIKE :pattern
        OR archives_filters::text LIKE :pattern
      SQL
    end

    def process(presentation)
      migrate_displayed_columns(presentation)
      ProcedurePresentation::ALL_FILTERS.each { migrate_filters(presentation, _1) }

      presentation.save(validate: false) if presentation.changed?

    # a column can fail to resolve for various reasons (deleted tdc, etc.)
    rescue ActiveRecord::RecordNotFound
    end

    private

    def migrate_displayed_columns(presentation)
      original = presentation.displayed_columns
      migrated = original.map { swap_to_new(_1) || _1 }.uniq(&:h_id)
      presentation.displayed_columns = migrated if migrated != original
    end

    def migrate_filters(presentation, attr)
      original = presentation.send(attr)
      migrated = original.map do |fc|
        new_column = swap_to_new(fc.column)
        new_column ? FilteredColumn.new(column: new_column, filter: fc.filter) : fc
      end
      presentation[attr] = migrated if migrated != original
    end

    def swap_to_new(column)
      return nil unless legacy_region_column?(column)

      new_column_id = column.h_id[:column_id].delete_suffix(LEGACY_SUFFIX) + NEW_SUFFIX
      Column.find(procedure_id: column.h_id[:procedure_id], column_id: new_column_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def legacy_region_column?(column)
      column.is_a?(Columns::JSONPathColumn) && column.h_id[:column_id].end_with?(LEGACY_SUFFIX)
    end
  end
end
