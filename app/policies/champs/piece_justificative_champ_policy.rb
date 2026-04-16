# frozen_string_literal: true

class Champs::PieceJustificativeChampPolicy < ChampPolicy
  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "wrong type de champ" if !record.piece_justificative? && !record.quotient_familial?
    super
  end
end
