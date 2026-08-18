# frozen_string_literal: true

require "administrate/field/base"

class EmailTemplateField < Administrate::Field::Base
  def name
    data.class::DISPLAYED_NAME
  end
end
