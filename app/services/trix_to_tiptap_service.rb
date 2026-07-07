# frozen_string_literal: true

class TrixToTiptapService
  def initialize(inline_resolver:)
    @inline_resolver = inline_resolver
  end

  def to_document(html)
    fragment = Nokogiri::HTML.fragment(html.to_s)
    blocks = collapse_empty_paragraphs(fragment.children.flat_map { block_nodes(_1) })
    blocks = [{ "type" => "paragraph" }] if blocks.empty?
    { "type" => "doc", "content" => blocks }
  end

  private

  # Trix marks empty lines with `<div><br></div>` and stacks blank lines; keeping
  # every one produces excessive spacing once re-rendered. We drop leading/trailing
  # empty paragraphs and collapse consecutive ones into a single blank line.
  def collapse_empty_paragraphs(blocks)
    blocks
      .each_with_object([]) do |block, kept|
        next if empty_paragraph?(block) && (kept.empty? || empty_paragraph?(kept.last))

        kept << block
      end
      .tap { |kept| kept.pop while empty_paragraph?(kept.last) }
  end

  def empty_paragraph?(block)
    block.is_a?(Hash) && block["type"] == "paragraph" && block["content"].blank?
  end

  def block_nodes(node)
    if node.text?
      return [] if node.text.strip.empty?

      [paragraph(inline_from_string(node.text))]
    elsif node.element?
      case node.name
      when 'ul' then [{ "type" => "bulletList", "content" => list_items(node) }]
      when 'ol' then [{ "type" => "orderedList", "content" => list_items(node) }]
      when 'h1' then [{ "type" => "heading", "attrs" => { "level" => 2 }, "content" => normalize_inline(inline_children(node, [])) }]
      when 'br' then []
      when 'div', 'p', 'blockquote' then [paragraph(inline_children(node, []))]
      else
        nested = node.children.flat_map { block_nodes(_1) }
        nested.empty? ? [paragraph(inline_children(node, []))] : nested
      end
    else
      []
    end
  end

  def list_items(node)
    node.element_children.to_a.filter { _1.name == 'li' }.map do |li|
      { "type" => "listItem", "content" => [paragraph(inline_children(li, []))] }
    end
  end

  def paragraph(content)
    content = normalize_inline(content)
    content.empty? ? { "type" => "paragraph" } : { "type" => "paragraph", "content" => content }
  end

  # A `<br>` terminating (or opening) a block is layout noise once the block itself
  # provides the line break, and stacked `<br>` produce extra blank lines. Edge
  # whitespace is trimmed since the rendered block would swallow it anyway.
  def normalize_inline(content)
    content = collapse_consecutive_hard_breaks(content)
    content = content.drop_while { hard_break?(_1) }
    content.pop while hard_break?(content.last)
    trim_edges(content)
  end

  def trim_edges(content)
    return content if content.empty?

    content = content.dup
    content[0] = content[0].merge("text" => content[0]["text"].lstrip) if text_node?(content.first)
    content[-1] = content[-1].merge("text" => content[-1]["text"].rstrip) if text_node?(content.last)
    content.reject { text_node?(_1) && _1["text"].empty? }
  end

  def text_node?(node)
    node.is_a?(Hash) && node["type"] == "text"
  end

  def collapse_consecutive_hard_breaks(content)
    content.each_with_object([]) do |node, kept|
      next if hard_break?(node) && hard_break?(kept.last)

      kept << node
    end
  end

  def hard_break?(node)
    node.is_a?(Hash) && node["type"] == "hardBreak"
  end

  def inline_children(node, marks)
    node.children.flat_map { inline_nodes(_1, marks) }
  end

  def inline_nodes(node, marks)
    if node.text?
      inline_from_string(node.text, marks)
    elsif node.element?
      case node.name
      when 'strong', 'b' then inline_children(node, add_mark(marks, { "type" => "bold" }))
      when 'em', 'i' then inline_children(node, add_mark(marks, { "type" => "italic" }))
      when 'a' then inline_children(node, add_mark(marks, link_mark(node)))
      when 'br' then [{ "type" => "hardBreak" }]
      else inline_children(node, marks)
      end
    else
      []
    end
  end

  def inline_from_string(text, marks = [])
    @inline_resolver.call(collapse_spaces(text)).map { |node| apply_marks(node, marks) }
  end

  # Collapse whitespace runs (HAML indentation and newlines) to a single space,
  # like HTML rendering does: the legacy email showed no line break for them.
  def collapse_spaces(text)
    text.gsub(/\s+/, ' ')
  end

  def apply_marks(node, marks)
    return node if marks.empty?

    node.merge("marks" => marks)
  end

  def add_mark(marks, mark)
    marks + [mark]
  end

  def link_mark(node)
    { "type" => "link", "attrs" => { "href" => node["href"].to_s } }
  end
end
