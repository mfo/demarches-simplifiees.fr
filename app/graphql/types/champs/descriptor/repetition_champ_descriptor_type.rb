# frozen_string_literal: true

module Types::Champs::Descriptor
  class RepetitionChampDescriptorType < Types::BaseObject
    implements Types::ChampDescriptorType
    form_structure!

    field :champ_descriptors, [Types::ChampDescriptorType], "Description des champs d’un bloc répétable.", null: true, method: :flat_children
  end
end
