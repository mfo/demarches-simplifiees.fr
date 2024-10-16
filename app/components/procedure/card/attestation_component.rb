# frozen_string_literal: true

class Procedure::Card::AttestationComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  private

  def edit_attestation_path
    if v2?
      helpers.edit_admin_procedure_attestation_template_v2_path(@procedure)
    else
      helpers.edit_admin_procedure_attestation_template_path(@procedure)
    end
  end

  def error_messages
    @procedure.errors.messages_for(:attestation_template).to_sentence
  end

  def v2?
    return false if @procedure.attestation_template.published?

    @procedure.attestation_templates_v2.any? || @procedure.feature_enabled?(:attestation_v2)
  end
end
