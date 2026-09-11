# frozen_string_literal: true

RSpec.describe Cron::CronJob, type: :job do
  describe '#schedulable?' do
    it 'is schedulable by default' do
      expect(Cron::CronJob.schedulable?).to be_truthy
    end
  end

  describe 'retries' do
    it 'caps Sidekiq retries: the next scheduled run is the retry' do
      expect(Cron::CronJob.get_sidekiq_options['retry']).to eq(2)
      expect(Cron::PurgeSoftDeletedBlobsJob.get_sidekiq_options['retry']).to eq(2)
    end

    it 'lets a job whose run cannot be caught up keep the full budget' do
      expect(Cron::PurgeOldBrevoMailsJob.get_sidekiq_options['retry']).to eq(ActiveJob::RetryOnStandardError::MAX_ATTEMPTS_JOBS)
      expect(Cron::Datagouv::AccountByMonthJob.get_sidekiq_options['retry']).to eq(ActiveJob::RetryOnStandardError::MAX_ATTEMPTS_JOBS)
      expect(Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob.get_sidekiq_options['retry']).to eq(ActiveJob::RetryOnStandardError::MAX_ATTEMPTS_JOBS)
    end

    it 'every cron job declares how a lost run is recovered' do
      Rails.application.eager_load!

      # Not `schedulable?`: it depends on env flags (ds_opendata_enabled,
      # CRON_JOBS_DISABLED) that are false here, which would silently skip the
      # whole data.gouv family.
      undeclared = Cron::CronJob.descendants
        .filter { |job| job.schedule_expression.present? }
        .reject(&:lost_run_recovery)

      expect(undeclared).to be_empty, <<~MSG
        #{undeclared.join(', ')}: add `recovers_by :next_run` or `recovers_by :never`.
        Question: if this run fails for good, does the next one catch up the lost work?
      MSG
    end

    it 'refuses an answer it does not know, without touching the job' do
      expect { Cron::UpdateStatsJob.recovers_by(:whenever) }
        .to raise_error(ArgumentError, /unknown recovery strategy/)

      expect(Cron::UpdateStatsJob.lost_run_recovery).to eq(:next_run)
    end
  end
end
