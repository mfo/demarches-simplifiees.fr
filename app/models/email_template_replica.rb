# frozen_string_literal: true

# Mirrors every write to the 6 legacy mail tables into email_templates, which is
# already filled but not read yet. Without it, a template edited between the
# deploy of this table and the STI switch would only resurface after a manual
# re-run of the copy task. Removed along with the legacy models.
class EmailTemplateReplica < ApplicationRecord
  self.table_name = "email_templates"

  # The replicated `type` names a legacy model that is still backed by its own
  # table: STI must not try to instantiate it from here.
  self.inheritance_column = nil

  # Same "most recently edited row wins" rule as the copy task, so a replication
  # racing the copy cannot undo it, whichever lands first. It says nothing about
  # the switch itself: once the reads move, only email_templates is written.
  ON_DUPLICATE = <<~SQL.squish
    subject = excluded.subject,
    body = excluded.body,
    json_subject = excluded.json_subject,
    json_body = excluded.json_body,
    updated_at = excluded.updated_at
    WHERE excluded.updated_at > email_templates.updated_at
  SQL

  def self.replicate(email_template)
    return if email_template.procedure_id.nil?

    row = {
      type: email_template.class.name,
      procedure_id: email_template.procedure_id,
      subject: email_template.subject,
      body: email_template.body,
      json_subject: email_template.json_subject,
      json_body: email_template.json_body,
      created_at: email_template.created_at,
      updated_at: email_template.updated_at,
    }

    upsert_all([row], unique_by: [:procedure_id, :type], on_duplicate: Arel.sql(ON_DUPLICATE))
  end

  def self.delete_replica(email_template)
    where(procedure_id: email_template.procedure_id, type: email_template.class.name).delete_all
  end
end
