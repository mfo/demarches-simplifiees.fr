# frozen_string_literal: true

class Dossiers::ExternalDataCardComponent < ApplicationComponent
  attr_reader :source, :untrusted

  def initialize(source: nil, untrusted: false)
    @source = source
    @untrusted = untrusted
  end
end
