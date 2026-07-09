# frozen_string_literal: true

class TypesDeChamp::PrefillBooleanTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def to_assignable_attributes(champ, value)
    casted_value = cast_value(value)
    return nil if casted_value.nil?

    { value: casted_value.to_s }
  end

  private

  def cast_value(value)
    case value
    when true, false, String, Numeric
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
