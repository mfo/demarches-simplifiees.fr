# frozen_string_literal: true

require "administrate/field/base"

# Vendored from the unmaintained administrate-field-enum gem (0.0.9), which pins
# administrate ~> 0.12 and blocked the upgrade to administrate 1.0.
# Renders an enum attribute as a humanized (optionally I18n-translated) value,
# and as a <select> on forms.
class EnumField < Administrate::Field::Base
  def to_s
    data.humanize unless data.nil?
  end

  def html_options
    options[:html] || {}
  end
end
