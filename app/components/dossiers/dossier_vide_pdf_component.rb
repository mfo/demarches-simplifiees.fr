# frozen_string_literal: true

class Dossiers::DossierVidePdfComponent < ApplicationComponent
  attr_reader :revision, :procedure

  def initialize(revision:)
    @revision = revision
    @procedure = revision.procedure
  end

  private

  def types_de_champ_public = revision.root_types_de_champ_public

  def organisation = procedure.organisation_name.presence || "En attente de saisie"

  # Empty field to fill in by hand: a bordered box (meaning carried by the preceding label)
  def fillable_box(height: :line)
    tag.div('', class: "box box--#{height}", aria: { hidden: true })
  end

  # Label / fillable area pair
  def fillable_field(label)
    tag.div(class: 'field-pair') do
      safe_join([tag.dt(label), tag.dd(fillable_box)])
    end
  end

  def render_champ(_type_de_champ) = "".html_safe # replaced in next commit
end
