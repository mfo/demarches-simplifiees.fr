# frozen_string_literal: true

class Dossiers::BatchOperationInlineButtonsComponent < ApplicationComponent
  attr_reader :opt, :icons, :form, :procedure

  def initialize(opt:, icons:, form:, procedure:)
    @opt = opt
    @icons = icons
    @form = form
    @procedure = procedure
  end
end
