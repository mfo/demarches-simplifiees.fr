# frozen_string_literal: true

module Emails
  # Slugs used in the admin URLs before the rename, read by the redirects of
  # config/routes/administrateur.rb.
  LEGACY_SLUGS = {
    "initiated_mail" => "depose",
    "received_mail" => "passe_en_instruction",
    "closed_mail" => "accepte",
    "refused_mail" => "refuse",
    "without_continuation" => "classe_sans_suite",
    "re_instructed_mail" => "repasse_en_instruction",
  }.freeze

  # Param keys posted by an editor rendered before the rename, keyed by current
  # slug. Read by EmailTemplatesController, so the save of an editor left open
  # across the deploy still lands. Drop with LEGACY_SLUGS and the redirects.
  LEGACY_PARAM_KEYS = {
    "depose" => "mails_initiated_mail",
    "passe_en_instruction" => "mails_received_mail",
    "accepte" => "mails_closed_mail",
    "refuse" => "mails_refused_mail",
    "classe_sans_suite" => "mails_without_continuation_mail",
    "repasse_en_instruction" => "mails_re_instructed_mail",
  }.freeze
end
