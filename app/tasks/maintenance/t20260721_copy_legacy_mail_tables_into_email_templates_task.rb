# frozen_string_literal: true

# Copy the 6 legacy per-type mail tables into the unified email_templates
# table (STI), ahead of the code switch. Idempotent: re-running upserts
# rows edited on the legacy tables since the previous run.
module Maintenance
  class T20260721CopyLegacyMailTablesIntoEmailTemplatesTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    run_on_first_deploy

    TABLES = {
      "initiated_mails" => "Emails::Depose",
      "received_mails" => "Emails::PasseEnInstruction",
      "closed_mails" => "Emails::Accepte",
      "refused_mails" => "Emails::Refuse",
      "without_continuation_mails" => "Emails::ClasseSansSuite",
      "re_instructed_mails" => "Emails::RepasseEnInstruction",
    }.freeze

    def collection
      TABLES.keys
    end

    def process(table)
      type = TABLES.fetch(table)

      # One statement per table, over 50-80k rows whose bodies are a few kB each:
      # the DISTINCT ON sorts on those, which can spill to disk and outlast the
      # 60s production statement_timeout. Raised for the transaction only.
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SET LOCAL statement_timeout = '5min'")

        # The IN also discards rows email_templates would reject: re_instructed_mails
        # is the only table without a FK to procedures, so it can hold orphans, and
        # the 5 others have a nullable procedure_id — a NULL never satisfies an IN.
        ActiveRecord::Base.connection.execute(<<~SQL.squish)
          INSERT INTO email_templates (type, procedure_id, subject, body, json_subject, json_body, created_at, updated_at)
          SELECT DISTINCT ON (procedure_id) '#{type}', procedure_id, subject, body, json_subject, json_body, created_at, updated_at
          FROM #{table}
          WHERE procedure_id IN (SELECT id FROM procedures)
          ORDER BY procedure_id, updated_at DESC
          ON CONFLICT (procedure_id, type) DO UPDATE
            SET subject = excluded.subject,
                body = excluded.body,
                json_subject = excluded.json_subject,
                json_body = excluded.json_body,
                updated_at = excluded.updated_at
            WHERE excluded.updated_at > email_templates.updated_at
        SQL
      end
    end
  end
end
