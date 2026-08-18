# frozen_string_literal: true

class TypesDeChamp::ExplicationTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def self.category = STRUCTURE
  def self.editable_option_keys = [:collapsible_explanation_enabled, :collapsible_explanation_text]

  def prefillable? = false
  def fillable? = false
  def libelle_optionnal? = true
  def tags_for_template = [].freeze
end
