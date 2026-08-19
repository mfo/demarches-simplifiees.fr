# frozen_string_literal: true

class DropDelayedJobs < ActiveRecord::Migration[8.0]
  def up
    # Migrations run before the new code goes live, so the previous release is
    # still scheduling Cron::ReleaseCrashedExportJob, which reads this table
    # every 10 minutes. Drop its cron entry first to close that window.
    Sidekiq::Cron::Job.destroy("Cron::ReleaseCrashedExportJob")

    drop_table :delayed_jobs
  end

  def down
    create_table :delayed_jobs, id: :serial do |t|
      t.integer :attempts, default: 0, null: false
      t.datetime :created_at, precision: nil
      t.string :cron
      t.datetime :failed_at, precision: nil
      t.text :handler, null: false
      t.text :last_error
      t.datetime :locked_at, precision: nil
      t.string :locked_by
      t.integer :priority, default: 0, null: false
      t.string :queue
      t.datetime :run_at, precision: nil
      t.datetime :updated_at, precision: nil
      t.index [:priority, :run_at], name: "delayed_jobs_priority"
    end
  end
end
