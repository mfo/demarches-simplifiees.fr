# frozen_string_literal: true

class Dossiers::RowShowComponent < ApplicationComponent
  attr_reader :label, :profile, :seen_at, :content_class
  attr_reader :updated_at, :updated_by, :source_stream

  renders_one :value
  renders_one :blank

  def initialize(label:, profile: nil, updated_at: nil, seen_at: nil, content_class: nil, updated_by: nil, source_stream: nil)
    @label = label
    @profile = profile
    @seen_at = seen_at
    @content_class = content_class
    @updated_at = updated_at
    @updated_by = updated_by
    @source_stream = source_stream
  end

  def usager?
    @profile == 'usager'
  end
end
