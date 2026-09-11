# frozen_string_literal: true

class Cron::CronJob < ApplicationJob
  # A cron job is scheduled again anyway: the next run is the retry. With the
  # default budget of 25 retries, a nightly job that fails on a statement
  # timeout is retried for about three weeks, so a dozen instances of the same
  # job overlap and every failure yields a dozen Sentry events. A job whose run
  # cannot be caught up by the next one keeps the full budget.
  #
  # This is a safety net, not the policy: it keeps a job that hasn't declared
  # anything from inheriting Active Job's 25 retries. The policy is `recovers_by`.
  use_sidekiq_retry(retry: 2)

  # Every cron job answers one question: if this run fails for good, does the next
  # one catch up the lost work? The retry budget follows from the answer, so the
  # answer is what a job declares -- not a number:
  #
  #   recovers_by :next_run -- yes, the schedule is the retry. 2 retries.
  #   recovers_by :never    -- no, the work is lost. Full retry budget.
  #
  # No default on purpose: `lost_run_recovery` stays nil until a job declares, and
  # spec/jobs/cron/cron_job_spec.rb fails on the job that hasn't answered.
  class_attribute :lost_run_recovery

  def self.recovers_by(strategy)
    case strategy
    when :next_run then use_sidekiq_retry(retry: 2)
    when :never then use_sidekiq_retry
    else raise ArgumentError, "unknown recovery strategy: #{strategy}"
    end

    self.lost_run_recovery = strategy
  end

  queue_as :default
  class_attribute :schedule_expression

  class << self
    def schedulable?
      ENV['CRON_JOBS_DISABLED'].blank?
    end

    def schedule
      remove if cron_expression_changed?

      if !scheduled?
        Sidekiq::Cron::Job.create(name: name, cron: cron_expression, class: name)
      end
    end

    def remove
      enqueued_cron_job.destroy if scheduled?
    end

    def display_schedule
      pp "#{name}: #{schedule_expression} cron(#{cron_expression})"
    end

    def scheduled?
      enqueued_cron_job.present?
    end

    def cron_expression_changed?
      scheduled? && enqueued_cron_job.cron != cron_expression
    end

    def enqueued_cron_job
      Sidekiq::Cron::Job.find(name)
    end

    def cron_expression
      Fugit.do_parse(schedule_expression, multi: :fail).to_cron_s
    end
  end
end
