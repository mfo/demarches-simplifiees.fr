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
      [
        Cron::PurgeOldBrevoMailsJob,
        Cron::NotifyDraftNotSubmittedJob,
        Cron::AdministrateurActivateBeforeExpirationJob,
        Cron::SendAPITokenExpirationNoticeJob,
      ].each do |job|
        expect(job.get_sidekiq_options['retry']).to eq(5)
        expect(job.get_sidekiq_options['attempt_threshold']).to eq(5)
      end
    end

    it 'gives the monthly data.gouv publications about four hours, reported once they persist' do
      expect(Cron::Datagouv::AccountByMonthJob.get_sidekiq_options['retry']).to eq(10)
      expect(Cron::Datagouv::AccountByMonthJob.get_sidekiq_options['attempt_threshold']).to eq(10)
    end

    it 'keeps the list of jobs raising their budget explicit' do
      Rails.application.eager_load!

      above_the_cap = Cron::CronJob.descendants
        .reject { |job| job <= Cron::Datagouv::BaseJob } # the whole family shares the budget asserted above
        .filter { |job| job.get_sidekiq_options['retry'] != 2 }

      expect(above_the_cap.map(&:name)).to match_array([
        'Cron::AdministrateurActivateBeforeExpirationJob',
        'Cron::NotifyDraftNotSubmittedJob',
        'Cron::PurgeOldBrevoMailsJob',
        'Cron::SendAPITokenExpirationNoticeJob',
      ])
    end
  end
end
