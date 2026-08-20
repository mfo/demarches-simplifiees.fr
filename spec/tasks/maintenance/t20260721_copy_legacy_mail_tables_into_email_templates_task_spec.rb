# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260721CopyLegacyMailTablesIntoEmailTemplatesTask do
    let(:procedure) { procedures.individual }

    def insert_legacy_initiated_mail(procedure_id, subject:, updated_at: Time.zone.now)
      connection = ActiveRecord::Base.connection
      connection.execute(<<~SQL.squish)
        INSERT INTO initiated_mails (subject, body, procedure_id, created_at, updated_at)
        VALUES (#{connection.quote(subject)}, #{connection.quote('legacy body')}, #{procedure_id}, NOW(), #{connection.quote(updated_at)})
      SQL
    end

    def email_templates_count
      ActiveRecord::Base.connection.select_value(<<~SQL.squish).to_i
        SELECT COUNT(*) FROM email_templates
        WHERE type = 'Emails::Depose' AND procedure_id = #{procedure.id}
      SQL
    end

    def email_templates_subject
      ActiveRecord::Base.connection.select_value(<<~SQL.squish)
        SELECT subject FROM email_templates
        WHERE type = 'Emails::Depose' AND procedure_id = #{procedure.id}
      SQL
    end

    it "copies the legacy row into email_templates" do
      insert_legacy_initiated_mail(procedure.id, subject: "legacy subject")

      expect { described_class.process("initiated_mails") }.to change { email_templates_count }.from(0).to(1)
    end

    it "is idempotent: re-running does not duplicate or error" do
      insert_legacy_initiated_mail(procedure.id, subject: "legacy subject")
      described_class.process("initiated_mails")

      expect { described_class.process("initiated_mails") }.not_to change { email_templates_count }
    end

    it "resyncs a legacy row edited after the first copy" do
      insert_legacy_initiated_mail(procedure.id, subject: "legacy subject")
      described_class.process("initiated_mails")

      ActiveRecord::Base.connection.execute(<<~SQL.squish)
        UPDATE initiated_mails SET subject = 'edited', updated_at = NOW() + interval '1 hour'
        WHERE procedure_id = #{procedure.id}
      SQL

      described_class.process("initiated_mails")

      expect(email_templates_subject).to eq("edited")
    end

    it "does not overwrite a newer email_templates row with stale legacy data" do
      insert_legacy_initiated_mail(procedure.id, subject: "legacy subject")
      described_class.process("initiated_mails")

      ActiveRecord::Base.connection.execute(<<~SQL.squish)
        UPDATE email_templates SET updated_at = NOW() + interval '1 hour', subject = 'newer'
        WHERE type = 'Emails::Depose' AND procedure_id = #{procedure.id}
      SQL

      described_class.process("initiated_mails")

      expect(email_templates_subject).to eq("newer")
    end

    it "skips legacy rows whose procedure no longer exists" do
      connection = ActiveRecord::Base.connection
      orphan_procedure_id = connection.select_value("SELECT COALESCE(MAX(id), 0) + 1000 FROM procedures").to_i
      connection.execute(<<~SQL.squish)
        INSERT INTO re_instructed_mails (subject, body, procedure_id, created_at, updated_at)
        VALUES (#{connection.quote('orphan subject')}, #{connection.quote('orphan body')}, #{orphan_procedure_id}, NOW(), NOW())
      SQL

      expect { described_class.process("re_instructed_mails") }.not_to raise_error

      count = connection.select_value(<<~SQL.squish).to_i
        SELECT COUNT(*) FROM email_templates
        WHERE type = 'Emails::RepasseEnInstruction' AND procedure_id = #{orphan_procedure_id}
      SQL
      expect(count).to eq(0)
    end

    # 5 of the 6 legacy tables have a nullable procedure_id, and email_templates
    # requires it: the IN is what keeps those rows out.
    it "skips legacy rows attached to no procedure" do
      connection = ActiveRecord::Base.connection
      connection.execute(<<~SQL.squish)
        INSERT INTO initiated_mails (subject, body, procedure_id, created_at, updated_at)
        VALUES (#{connection.quote('no procedure')}, #{connection.quote('legacy body')}, NULL, NOW(), NOW())
      SQL

      expect { described_class.process("initiated_mails") }.not_to raise_error

      count = connection.select_value(<<~SQL.squish).to_i
        SELECT COUNT(*) FROM email_templates WHERE subject = #{connection.quote('no procedure')}
      SQL
      expect(count).to eq(0)
    end
  end
end
