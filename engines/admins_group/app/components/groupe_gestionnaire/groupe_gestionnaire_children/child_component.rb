# frozen_string_literal: true

class GroupeGestionnaire::GroupeGestionnaireChildren::ChildComponent < GroupeGestionnaire::BaseComponent
  include ApplicationHelper

  def initialize(groupe_gestionnaire:, child:)
    @groupe_gestionnaire = groupe_gestionnaire
    @child = child
  end

  def name
    @child.name
  end

  def created_at
    I18n.l(@child.created_at.to_date, format: :short)
  end
end
