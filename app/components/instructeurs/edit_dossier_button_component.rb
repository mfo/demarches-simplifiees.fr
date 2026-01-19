# frozen_string_literal: true

class Instructeurs::EditDossierButtonComponent < ApplicationComponent
  attr_reader :dossier

  def initialize(dossier:)
    @dossier = dossier
  end

  def title
    if dossier.en_instruction?
      t('.title.en_instruction')
    elsif dossier.termine?
      t('.title.termine')
    else
      t('.title.owner_is_self')
    end
  end
end
