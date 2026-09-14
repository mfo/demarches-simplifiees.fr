# frozen_string_literal: true

class TypesDeChampEditor::InfoReferentielComponent < ApplicationComponent
  attr_reader :procedure, :type_de_champ
  delegate :referentiel, to: :type_de_champ
  delegate :ready?, to: :referentiel, allow_nil: true

  def initialize(procedure:, type_de_champ:)
    @procedure = procedure
    @type_de_champ = type_de_champ
  end
end
