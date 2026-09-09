# frozen_string_literal: true

# Free text spanning several lines (the motivation of a decision): a text
# node per line separated by hard breaks, so the value stays inside the
# paragraph that mentions it.
class ChampPresentations::MultilineTextPresentation < ChampPresentations::BasePresentation
  attr_reader :text

  def initialize(text)
    @text = text.to_s.gsub("\r\n", "\n").strip
  end

  # A newline, or the `<br>` an instructeur types in a motivation: both reach
  # the tree as raw text, and both mean a line. The break comes first so that a
  # newline touching it is swallowed with it, rather than counted twice.
  SEPARATOR = Regexp.union(TiptapService::LINE_BREAK, "\n")

  def to_s = text

  def to_tiptap_nodes
    text.split(SEPARATOR, -1).flat_map.with_index do |line, index|
      [({ type: 'hardBreak' } if index > 0), ({ type: 'text', text: line } unless line.empty?)].compact
    end
  end
end
