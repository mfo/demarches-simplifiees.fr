# frozen_string_literal: true

class Dossiers::ChampUpdatedComponent < ApplicationComponent
  attr_reader :updated_at, :seen_at, :updated_by, :source_stream

  def initialize(updated_at: nil, seen_at: nil, updated_by: nil, source_stream: nil)
    @updated_at = updated_at
    @seen_at = seen_at
    @updated_by = updated_by
    @source_stream = source_stream
  end

  def badge_updated_class
    class_names(
      "fr-badge fr-badge--sm" => true,
      "fr-badge--new" => seen_at.present? && updated_at&.>(seen_at)
    )
  end

  def source
    if instructeur?
      t('.instructeur')
    else
      t('.usager')
    end
  end

  def updated_by_instructeur?
    updated_by.present? && instructeur?
  end

  def instructeur?
    source_stream == Champ::INSTRUCTEUR_BUFFER_STREAM
  end

  def tooltip_id
    @tooltip_id ||= "tooltip-#{SecureRandom.uuid}"
  end

  def render?
    updated_at.present?
  end
end
