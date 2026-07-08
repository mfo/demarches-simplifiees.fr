# frozen_string_literal: true

module InstructionButtonHelper
  def instruction_modal_title_data(dossier: nil, batch: false)
    count = batch ? 2 : 1

    {
      default_title: t(
        "instructeurs.instruction_button_component.modal.title",
        count:,
        dossier_id: dossier&.id,
        owner_name: dossier&.owner_name
      ),
      accept: instruction_modal_action_title(:accept, dossier:, batch:),
      refuse: instruction_modal_action_title(:refuse, dossier:, batch:),
      'without-continuation': instruction_modal_action_title(:without_continuation, dossier:, batch:),
    }
  end

  def instruction_modal_action_title(action, dossier:, batch:)
    count = batch ? 2 : 1
    title = t("instructeurs.instruction_button_component.modal.actions.#{action}", count:)

    return title if batch

    "#{title} n° #{dossier.id} - #{dossier.owner_name}"
  end

  def instruction_options(batch:)
    [
      instruction_option(
        key: :accepter,
        operation: 'accept',
        action: BatchOperation.operations.fetch(:accepter),
        icon: 'fr-icon-checkbox-circle-fill fr-text-default--success',
        batch:
      ),
      instruction_option(
        key: :refuser,
        operation: 'refuse',
        action: BatchOperation.operations.fetch(:refuser),
        icon: 'fr-icon-close-circle-fill fr-text-default--warning',
        batch:
      ),
      instruction_option(
        key: :classer_sans_suite,
        operation: 'without-continuation',
        action: BatchOperation.operations.fetch(:classer_sans_suite),
        icon: 'fr-icon-intermediate-circle-fill fr-text-mention--grey',
        batch:
      ),
    ]
  end

  def instruction_option_for(operation:, batch:)
    instruction_options(batch:).find { _1[:operation] == operation }
  end

  def instruction_attestation_context(operation:, batch:, procedure:, dossier:)
    case operation
    when "accept"
      {
        template: batch ? procedure.attestation_acceptation_template : dossier.attestation_acceptation_template,
        kind: "acceptation",
        title: "L’acceptation du dossier génère automatiquement une attestation à télécharger par l’usager",
      }
    when "refuse"
      {
        template: batch ? procedure.attestation_refus_template : dossier.attestation_refus_template,
        kind: "refus",
        title: "Le refus du dossier génère automatiquement une attestation à télécharger par l’usager",
      }
    else
      { template: nil, kind: nil, title: nil }
    end
  end

  private

  def instruction_option(key:, operation:, action:, icon:, batch:)
    count = batch ? 2 : 1

    {
      title: t("instructeurs.instruction_button_component.action_buttons.#{key}.title", count:),
      desc: t("instructeurs.instruction_button_component.action_buttons.#{key}.desc", count:),
      label: t("instructeurs.instruction_button_component.action_buttons.#{key}.motivation_label", count:),
      hint: t("instructeurs.instruction_button_component.action_buttons.#{key}.motivation_hint", count:),
      operation:,
      action:,
      icon:,
    }
  end
end
