# frozen_string_literal: true

class Champs::CarteChampPolicy < ChampPolicy
  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "wrong type de champ" unless record.carte?
    super
  end
end
