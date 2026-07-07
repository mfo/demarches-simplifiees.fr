# frozen_string_literal: true

class Instructeurs::ReaffectationFormComponent < ApplicationComponent
  attr_reader :dossier, :groupe_instructeur, :groupes_instructeurs

  def initialize(dossier:, groupe_instructeur:, groupes_instructeurs:)
    @dossier = dossier
    @groupe_instructeur = groupe_instructeur
    @groupes_instructeurs = groupes_instructeurs
  end

  private

  def group_items
    groupes_instructeurs.map { |g| { label: g.label, value: g.id.to_s } }
  end
end
