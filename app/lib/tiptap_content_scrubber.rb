# frozen_string_literal: true

# Scrubber for admin-authored TipTap content rendered into PDF attestations
# (attestation v2 body and signature preview). Much stricter than the default
# Rails safe list: only what TiptapService#to_html can emit survives.
#
#   - elements: the TipTap node vocabulary (plus <header>); everything else
#     is stripped, and <script>/<style> are pruned with their content;
#   - class: only the classes TiptapService and ChampPresentations produce;
#   - style: only text-align with a fixed set of values - Loofah's own CSS
#     safe list is much broader and let color, width etc. through to the PDF.
class TiptapContentScrubber < Rails::HTML::PermitScrubber
  ALLOWED_TAGS = %w[header div p h1 h2 h3 h4 h5 h6 ul ol li dl dt dd br strong em u mark].freeze
  ALLOWED_ATTRIBUTES = %w[class style].freeze
  ALLOWED_CLASSES = %w[body-start page-break tdc-repetition invisible].freeze
  ALLOWED_STYLES = { 'text-align' => %w[left center right justify] }.freeze
  PRUNE = %w[script style].freeze

  def initialize
    super
    self.tags = ALLOWED_TAGS
    self.attributes = ALLOWED_ATTRIBUTES
  end

  def scrub_node(node)
    PRUNE.include?(node.name) ? node.remove : super
  end

  def scrub_attributes(node)
    super
    scrub_class(node) if node['class']
    scrub_style(node) if node['style']
  end

  private

  def scrub_class(node)
    kept = node['class'].split & ALLOWED_CLASSES

    if kept.empty?
      node.remove_attribute('class')
    else
      node['class'] = kept.join(' ')
    end
  end

  def scrub_style(node)
    kept = node['style'].split(';').filter_map do |declaration|
      property, value = declaration.split(':', 2).map(&:strip)
      next if property.blank? || value.blank?

      "#{property}: #{value}" if ALLOWED_STYLES[property]&.include?(value)
    end

    if kept.empty?
      node.remove_attribute('style')
    else
      node['style'] = kept.join('; ')
    end
  end
end
