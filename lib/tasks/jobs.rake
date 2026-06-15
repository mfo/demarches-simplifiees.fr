# frozen_string_literal: true

namespace :jobs do
  desc 'Schedule all schedulable cron jobs'
  task schedule: :environment do
    jobs = schedulable_jobs
    jobs.each(&:schedule)
    prune_orphaned_cron_jobs(jobs)
  end

  desc 'Display schedule for all schedulable cron jobs'
  task display_schedule: :environment do
    schedulable_jobs.each(&:display_schedule)
  end

  def schedulable_jobs
    glob = Rails.root.join('app', 'jobs', '**', '*_job.rb')
    Dir.glob(glob).each { |f| require f }
    Cron::CronJob.descendants.filter(&:schedulable?)
  end

  # Remove cron schedules left in Redis after their job class was deleted or
  # renamed. sidekiq-cron's own `destroy_removed_jobs` only considers jobs with
  # source == "schedule", but ours are created via `Sidekiq::Cron::Job.create`
  # (source == "dynamic"), so we prune by comparing against the known classes.
  def prune_orphaned_cron_jobs(jobs)
    known_classes = jobs.map(&:name).to_set
    Sidekiq::Cron::Job.all.each do |cron_job| # rubocop:disable Rails/FindEach -- not an ActiveRecord relation
      cron_job.destroy unless known_classes.include?(cron_job.klass)
    end
  end
end
