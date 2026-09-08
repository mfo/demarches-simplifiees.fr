# frozen_string_literal: true

class GroupeGestionnaire::Card::ChildrenComponent < GroupeGestionnaire::BaseComponent
  def initialize(groupe_gestionnaire:, path:)
    @groupe_gestionnaire = groupe_gestionnaire
    @path = path
  end
end
