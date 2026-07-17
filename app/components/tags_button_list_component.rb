# frozen_string_literal: true

class TagsButtonListComponent < ApplicationComponent
  attr_reader :tags

  def initialize(tags:)
    @tags = tags
  end

  # Unique per instance so several tag lists on one page (e.g. the mail subject
  # and body editors) don't wire their labels to another list's checkbox.
  def optional_toggle_id
    @optional_toggle_id ||= "show_optional_#{SecureRandom.hex(4)}"
  end

  def button_label(tag)
    tag[:libelle].truncate_words(12)
  end

  def button_title(tag)
    tag[:description].presence || tag[:libelle]
  end

  def each_category
    tags.each_pair do |category, tags|
      yield category, tags, can_toggle_optional?(category)
    end
  end

  private

  def optional_or_conditional_tag?(tag)
    !tag[:mandatory] || tag[:conditional]
  end

  def can_toggle_optional?(category)
    return false if category != :champ_public && category != :champ_private

    tags[category].any? { optional_or_conditional_tag?(_1) }
  end
end
