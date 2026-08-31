# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    def visible?(context)
      super && visible_unless_deprecated?(context)
    end

    private

    def visible_unless_deprecated?(context)
      if name == "options" && owner.name == 'Types::ChampDescriptorType'
        !context.has_fragments?([:PaysChampDescriptor, :RegionChampDescriptor, :DepartementChampDescriptor])
      else
        true
      end
    end
  end
end
