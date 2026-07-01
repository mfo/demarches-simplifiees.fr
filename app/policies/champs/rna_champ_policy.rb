# frozen_string_literal: true

class Champs::RNAChampPolicy < ChampPolicy
  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "wrong type de champ" unless record.rna?
    super
  end
end
