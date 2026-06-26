# frozen_string_literal: true

class ChampPresentations::CartePresentation < ChampPresentations::BasePresentation
  attr_reader :geo_areas

  def initialize(geo_areas)
    @geo_areas = geo_areas
  end

  def to_s
    geo_areas.map { format_label(_1) }.join("\n")
  end

  def to_tiptap_node
    {
      type: 'bulletList',
      content: geo_areas.map do |geo_area|
        {
          type: 'listItem',
          content: [
            {
              type: 'paragraph',
              content: [
                {
                  type: 'text',
                  text: format_label(geo_area),
                },
              ],
            },
          ],
        }
      end,
    }
  end

  private

  def format_label(geo_area)
    label = geo_area.label
    if geo_area.point?
      coords = geo_area.geometry['coordinates']
      "#{label} (#{coords[1].round(6)}, #{coords[0].round(6)})"
    else
      label
    end
  end
end
