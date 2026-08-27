# frozen_string_literal: true

class TypesDeChampEditor::EditorComponent < ApplicationComponent
  def initialize(revision:, is_annotation: false)
    @revision = revision
    @is_annotation = is_annotation
  end

  private

  def annotations?
    @is_annotation
  end

  def coordinates
    if annotations?
      @revision.private_revision_type_de_champs
    else
      @revision.public_revision_type_de_champs
    end
  end

  def validation_context
    if annotations?
      :private_type_de_champs_editor
    else
      :public_type_de_champs_editor
    end
  end
end
