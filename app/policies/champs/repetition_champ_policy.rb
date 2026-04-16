# frozen_string_literal: true

class Champs::RepetitionChampPolicy < ChampPolicy
  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "wrong type de champ" unless record.repetition?
    super
  end
end
