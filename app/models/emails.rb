# frozen_string_literal: true

module Emails
  # Slugs used in the admin URLs before the rename. Only the redirects of
  # config/routes/administrateur.rb read this: drop both together.
  LEGACY_SLUGS = {
    "initiated_mail" => "depose",
    "received_mail" => "passe_en_instruction",
    "closed_mail" => "accepte",
    "refused_mail" => "refuse",
    "without_continuation" => "classe_sans_suite",
    "re_instructed_mail" => "repasse_en_instruction",
  }.freeze
end
