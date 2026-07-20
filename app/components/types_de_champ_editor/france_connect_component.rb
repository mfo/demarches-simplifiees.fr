# frozen_string_literal: true

class TypesDeChampEditor::FranceConnectComponent < ApplicationComponent
  attr_reader :type_de_champ

  def initialize(procedure:, type_de_champ:)
    @procedure = procedure
    @type_de_champ = type_de_champ
  end

  private

  def justificatif_label
    t(".justificatif_labels.#{type_de_champ.type_champ}")
  end
end
