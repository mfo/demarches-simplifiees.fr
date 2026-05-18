# frozen_string_literal: true

class AutosaveNoticeTurboStreamComponent < ApplicationComponent
  attr_reader :label_scope

  def initialize(success: true, label_scope: :form)
    @success = success
    @label_scope = label_scope
  end

  def success? = @success

  def label
    success? ? t(".#{label_scope}.saved") : t(".#{label_scope}.error")
  end
end
