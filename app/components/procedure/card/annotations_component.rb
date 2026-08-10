# frozen_string_literal: true

class Procedure::Card::AnnotationsComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
    @count = @procedure.draft_revision.types_de_champ.count(&:private?)
  end

  private

  def error_messages
    @procedure.errors.messages_for(:private_draft_type_de_champs).to_sentence
  end
end
