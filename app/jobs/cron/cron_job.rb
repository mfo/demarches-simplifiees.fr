# frozen_string_literal: true

class Cron::CronJob < ApplicationJob
  # A cron job is scheduled again anyway: the next run is the retry. With the
  # default budget of 25 retries, a nightly job that fails on a statement
  # timeout is retried for about three weeks, so a dozen instances of the same
  # job overlap and every failure yields a dozen Sentry events.
  #
  # `perform` recomputes the current date at every attempt, so once the retries reach
  # the next run (retry 14 lands a day later) they no longer redo the lost work: they
  # run the next run's scope, in addition to the next run. Past its own window, a retry
  # stops being a catch-up and becomes a duplicate -- which is why a budget is sized to
  # the window rather than to MAX_ATTEMPTS_JOBS.
  #
  # The line below is a safety net, not the policy: it keeps an undeclared job from
  # inheriting Active Job's 25 retries. The policy is `recovers_by`.
  use_sidekiq_retry(max_retry: 2)

  # Every cron job answers one question: if this run fails for good, does the next one
  # catch up the lost work? The budget follows from the answer, so the answer is what a
  # job declares -- not a number:
  #
  #   recovers_by :next_run          -- yes, the schedule is the retry (2 retries, 30 s)
  #   recovers_by :next_run_but_late -- yes, but only at the next monthly run, so it is
  #                                     worth waiting out an outage (10 retries, ~4 h)
  #   recovers_by :never             -- no, the scope closes before the next run, and a
  #                                     retry past that only duplicates (5 retries, 7 min)
  #
  # No default on purpose: `lost_run_recovery` stays nil until a job declares, and
  # spec/jobs/cron/cron_job_spec.rb fails on any job that hasn't answered.
  class_attribute :lost_run_recovery

  def self.recovers_by(strategy)
    case strategy
    when :next_run then use_sidekiq_retry(max_retry: 2)
    when :next_run_but_late then use_sidekiq_retry(max_retry: 10, report_after_attempts: 10)
    when :never then use_sidekiq_retry(max_retry: 5, report_after_attempts: 5)
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
