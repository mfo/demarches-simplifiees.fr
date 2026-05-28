# frozen_string_literal: true

class ProcedureExportService::XlsxStreamer
  # Bornes de largeur de colonne (en caractères). Le streaming interdit l'autofit
  # de caxlsx (qui scannait toutes les lignes) car xlsxtream écrit <cols> avant la
  # moindre ligne. On dimensionne donc au contenu *observé* — toutes les lignes
  # pour les feuilles bufferisées, le 1er batch pour la feuille Dossiers streamée —
  # borné entre MIN et MAX pour rester lisible sans qu'une cellule à rallonge
  # (longue adresse, email…) n'étale la colonne à l'infini.
  MIN_WIDTH = 12
  MAX_WIDTH = 100

  def initialize(io)
    @io = io
  end

  def open
    Xlsxtream::Workbook.open(@io) do |workbook|
      @workbook = workbook
      yield(self)
    end
  end

  # Feuille dont toutes les lignes sont connues d'avance (feuilles bufferisées) :
  # on ouvre, écrit l'en-tête stylé puis on yielde la feuille pour les lignes.
  def write_sheet(name, headers:, widths: nil)
    @workbook.write_worksheet(sheet_options(name, headers, widths)) do |sheet|
      sheet.add_styled_row(headers, style: Xlsxtream::HEADER_STYLE)
      # On yielde la feuille xlsxtream brute : xlsxtream coerce lui-même nil → cellule
      # vide et Symbol → texte (cf. Row#to_xml). Les valeurs sont par ailleurs déjà
      # résolues et typées en amont par XlsxExport.cell_value (parité SpreadsheetArchitect,
      # ex. booléen non typé → texte). Pas d'échappement de formule : une cellule chaîne
      # xlsx n'est jamais évaluée (seul un <f> l'est).
      yield(sheet)
    end
  end

  # Feuille streamée (Dossiers) : les largeurs ne sont connues qu'après résolution
  # du 1er batch, donc on ouvre la feuille à la demande (API impérative d'xlsxtream).
  # L'appelant ajoute les lignes au fil de l'eau puis appelle close_sheet.
  def open_sheet(name, headers:, widths:)
    sheet = @workbook.add_worksheet(sheet_options(name, headers, widths))
    sheet.add_styled_row(headers, style: Xlsxtream::HEADER_STYLE)
    sheet
  end

  def close_sheet(sheet) = sheet.close

  # Largeur par colonne = max(longueur du libellé d'en-tête, plus long contenu
  # observé), borné [MIN_WIDTH, MAX_WIDTH].
  def self.column_widths(headers, rows)
    Array(headers).each_index.map do |index|
      content = rows.filter_map { cell_width(it[index]) }.max || 0
      [headers[index].to_s.length, content].max.clamp(MIN_WIDTH, MAX_WIDTH)
    end
  end

  # Largeur d'affichage approximative d'une valeur déjà résolue. Les dates et
  # datetimes sont rendues via les formats forcés (cf. lib/core_ext/xlsxtream.rb),
  # pas via leur #to_s, d'où le calcul dédié. DateTime < Date : tester en premier.
  def self.cell_width(value)
    case value
    when nil then nil
    when DateTime, Time then 20 # "yyyy-mm-dd h:mm AM/PM"
    when Date then 10           # "yyyy-mm-dd"
    else value.to_s.length
    end
  end

  private

  def sheet_options(name, headers, widths)
    widths ||= self.class.column_widths(headers, [])
    {
      name: ProcedureExportService.sanitize_sheet_name(name),
      columns: widths.map { { width_chars: it } },
    }
  end
end
