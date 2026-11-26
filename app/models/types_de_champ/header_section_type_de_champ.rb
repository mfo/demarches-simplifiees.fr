# frozen_string_literal: true

class TypesDeChamp::HeaderSectionTypeDeChamp < TypeDeChamp
  def self.category = STRUCTURE
  def self.icon = 'fr-icon-heading'
  def self.option_keys = [:header_section_level]

  MAX_LEVEL = 3

  store_accessor :options, :header_section_level

  validates :header_section_level, numericality: {
    only_integer: true,
    in: 1..MAX_LEVEL,
    max: MAX_LEVEL,
    allow_blank: true,
    message: :invalid_level,
  }, if: :header_section_level_edited?

  # a copy keeps the level of its original, an out of range legacy one included
  def initialize_dup(*)
    super
    @copy = true
  end

  def fillable? = false
  def description_configurable? = false
  def has_label? = false
  def tags_for_template = [].freeze

  # its level is its place in the tree: a change of level is a move
  def revision_diff_options = {}

  def header_section_level_value
    if header_section_level.presence
      header_section_level.to_i
    else
      1
    end
  end

  def check_coherent_header_level(upper_tdcs)
    previous_level = previous_section_level(upper_tdcs)
    current_level = header_section_level_value.to_i

    difference = current_level - previous_level
    if current_level > previous_level && difference != 1
      I18n.t('activerecord.errors.type_de_champ.attributes.header_section_level.gap_error', level: current_level - 1)
    else
      nil
    end
  end

  private

  def header_section_level_edited? = header_section_level_changed? && !@copy
end
