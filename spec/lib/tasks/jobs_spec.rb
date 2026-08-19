# frozen_string_literal: true

describe 'jobs' do
  describe 'schedule' do
    subject { Rake::Task['jobs:schedule'].invoke }

    after(:each) do
      Rake::Task['jobs:schedule'].reenable
      # jobs:schedule now always writes to Redis, which is not rolled back with
      # the example: drop every schedule it created.
      Sidekiq::Cron::Job.destroy_all!
    end

    it 'runs' do
      expect { subject }.not_to raise_error
    end

    context 'when an orphaned cron job remains in Redis' do
      let(:known_class) { Cron::ExpiredDossiersBrouillonDeletionJob.name }
      let(:orphan_class) { 'Cron::ThisJobNoLongerExistsJob' }

      before do
        Sidekiq::Cron::Job.create(name: known_class, cron: '0 0 * * *', class: known_class)
        Sidekiq::Cron::Job.create(name: orphan_class, cron: '0 0 * * *', class: orphan_class)
      end

      it 'destroys cron jobs whose class is no longer schedulable' do
        expect { subject }.to change { Sidekiq::Cron::Job.find(orphan_class) }.to(nil)
      end

      it 'keeps cron jobs whose class is still schedulable' do
        subject

        expect(Sidekiq::Cron::Job.find(known_class)).to be_present
      end
    end
  end
end
