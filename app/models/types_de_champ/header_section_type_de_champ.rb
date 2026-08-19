# frozen_string_literal: true

class TypesDeChamp::HeaderSectionTypeDeChamp < TypeDeChamp
  def self.category = STRUCTURE
  def self.editable_option_keys = [:header_section_level]

  def fillable? = false
  def description_configurable? = false
  def has_label? = false
  def tags_for_template = [].freeze
end
