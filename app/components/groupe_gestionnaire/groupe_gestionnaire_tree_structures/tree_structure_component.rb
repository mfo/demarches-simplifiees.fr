# frozen_string_literal: true

class GroupeGestionnaire::GroupeGestionnaireTreeStructures::TreeStructureComponent < GroupeGestionnaire::BaseComponent
  include ApplicationHelper

  def initialize(parent:, children:)
    @parent = parent
    @children = children
  end
end
