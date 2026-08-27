# frozen_string_literal: true

class TypesDeChampEditor::HeaderSectionsSummaryComponent < ApplicationComponent
  def initialize(procedure:, is_private:)
    @procedure = procedure
    @is_private = is_private
  end

  def header_sections
    coordinates = if @is_private
      @procedure.draft_revision.private_revision_type_de_champs
    else
      @procedure.draft_revision.public_revision_type_de_champs
    end

    coordinates.filter { _1.type_de_champ.header_section? }
  end

  def href(header_section) # used by type de champ editor to anchor elements
    "##{dom_id(header_section, :type_de_champ_editor)}"
  end
end
