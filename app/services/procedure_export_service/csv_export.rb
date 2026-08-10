# frozen_string_literal: true

# Streams a procedure's dossiers into a CSV file with bounded memory: rows are
# written batch by batch via DossierPreloader, so only one batch of dossiers
# (and their champs) is materialized at a time. Mirrors XlsxExport without its
# secondary sheets — the CSV is single-sheet, établissement columns inline.
class ProcedureExportService::CsvExport
  def initialize(procedure:, dossiers:, export_template:)
    @procedure = procedure
    @dossiers = dossiers
    @export_template = export_template
  end

  def write_to(io)
    csv = CSV.new(io)
    headers_written = false

    DossierPreloader
      .new(@dossiers.ordered_for_export)
      .in_batches(includes: DossierPreloader::SHEET_EXPORT_INCLUDES) do |batch|
      batch.each do |dossier|
        columns = dossier.spreadsheet_columns_csv(types_de_champ:, export_template: @export_template)

        unless headers_written
          csv << columns.map(&:first)
          headers_written = true
        end

        csv << columns.map { |(_libelle, value)| resolve(dossier, value) }
      end
    end
  end

  private

  def resolve(instance, value)
    if value.is_a?(Symbol)
      instance.send(value)
    else
      value
    end
  end

  def types_de_champ = @types_de_champ ||= @procedure.type_de_champs_for_procedure_export.to_a
end
