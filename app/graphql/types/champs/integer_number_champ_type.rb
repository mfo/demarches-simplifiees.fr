# frozen_string_literal: true

module Types::Champs
  class IntegerNumberChampType < Types::BaseObject
    implements Types::ChampType

    field :value, GraphQL::Types::BigInt, null: true

    def value
      object.value.presence&.to_i
    end
  end
end
