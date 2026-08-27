# frozen_string_literal: true

require "administrate/field/base"

class TypeDeChampsCollectionField < Administrate::Field::Base
  def to_s
    data
  end
end
