# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :instructeur, :administrateur, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user = user
    @instructeur = user&.instructeur
    @administrateur = user&.administrateur
    @record = record
  end

  private

  def instructeur? = instructeur.present?
  def administrateur? = administrateur.present?
end
