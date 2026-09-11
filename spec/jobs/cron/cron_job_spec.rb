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
      expect(Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob.get_sidekiq_options['retry']).to eq(2)
    end

    it 'gives a job whose run cannot be caught up a few minutes, reported once it persists' do
      expect(Cron::PurgeOldBrevoMailsJob.get_sidekiq_options['retry']).to eq(5)
      expect(Cron::PurgeOldBrevoMailsJob.get_sidekiq_options['attempt_threshold']).to eq(5)
    end

    it 'gives the monthly data.gouv publications about four hours, reported once they persist' do
      expect(Cron::Datagouv::AccountByMonthJob.get_sidekiq_options['retry']).to eq(10)
      expect(Cron::Datagouv::AccountByMonthJob.get_sidekiq_options['attempt_threshold']).to eq(10)
    end
  end
end
