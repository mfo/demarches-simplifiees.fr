# frozen_string_literal: true

# Base class of every component of the "groupe gestionnaire" feature. It carries
# what the shared ApplicationComponent must not know about: the gestionnaire
# profile, which only exists on the instances enabling the feature.
class GroupeGestionnaire::BaseComponent < ApplicationComponent
  def current_gestionnaire
    controller.current_gestionnaire
  end
end
