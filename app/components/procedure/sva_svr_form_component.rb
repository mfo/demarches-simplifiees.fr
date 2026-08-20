# frozen_string_literal: true

class Procedure::SVASVRFormComponent < ApplicationComponent
  attr_reader :procedure, :configuration

  def initialize(procedure:, configuration:)
    @procedure = procedure
    @configuration = configuration
  end

  private

  def form_disabled?
    return true if !procedure.feature_enabled?(:sva)
    return true if procedure.declarative?
    return false if procedure.brouillon?

    procedure.sva_svr_enabled?
  end

  def decision_buttons
    [
      { label: t(".decision_buttons.disabled"), value: "disabled", disabled: form_disabled? },
      { label: t(".decision_buttons.sva"), value: "sva", hint: t(".decision_buttons.sva_hint"), disabled: form_disabled? },
      { label: t(".decision_buttons.svr"), value: "svr", hint: t(".decision_buttons.svr_hint"), disabled: form_disabled? },
    ]
  end

  def resume_buttons
    [
      {
        value: "continue",
        label: t(".resume_buttons.continue_label"),
        hint: t(".resume_buttons.continue_hint"),
        disabled: form_disabled?,
      },
      {
        value: "reset",
        label: t(".resume_buttons.reset_label"),
        hint: t(".resume_buttons.reset_hint"),
        disabled: form_disabled?,
      },
    ]
  end
end
