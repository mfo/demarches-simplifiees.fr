# frozen_string_literal: true

require "administrate/field/base"

class OtpAttemptField < Administrate::Field::Base
  def required?
    true
  end
end
