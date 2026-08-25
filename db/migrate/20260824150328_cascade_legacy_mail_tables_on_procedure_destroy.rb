# frozen_string_literal: true

class CascadeLegacyMailTablesOnProcedureDestroy < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # Their rows are no longer covered by any Active Record association since the
  # STI switch, so destroying a procedure hits these foreign keys. The tables
  # are dropped once the switch is deployed for good.
  LEGACY_MAIL_TABLES = [
    :initiated_mails,
    :received_mails,
    :closed_mails,
    :refused_mails,
    :without_continuation_mails,
  ].freeze

  def up
    LEGACY_MAIL_TABLES.each do |table|
      remove_foreign_key table, :procedures
      add_foreign_key table, :procedures, on_delete: :cascade, validate: false
      validate_foreign_key table, :procedures
    end
  end

  def down
    LEGACY_MAIL_TABLES.each do |table|
      remove_foreign_key table, :procedures
      add_foreign_key table, :procedures, validate: false
      validate_foreign_key table, :procedures
    end
  end
end
