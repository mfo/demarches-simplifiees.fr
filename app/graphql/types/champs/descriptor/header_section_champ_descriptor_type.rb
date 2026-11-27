# frozen_string_literal: true

module Types::Champs::Descriptor
  class HeaderSectionChampDescriptorType < Types::BaseObject
    implements Types::ChampDescriptorType
    form_structure!

    field :level, Int, null: false
  end
end
