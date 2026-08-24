# frozen_string_literal: true

class IndifferentJsonbType < ActiveRecord::Type::Json
  def deserialize(value) = (super || {}).with_indifferent_access
  def cast(value) = (super || {}).with_indifferent_access
end
