# frozen_string_literal: true

include ActiveJob::TestHelper

RSpec.describe ApplicationJob, type: :job do
  describe 'perform' do
    before do
      allow(Rails.logger).to receive(:info)
    end

    it 'logs start time and end time' do
      perform_enqueued_jobs { ChildJob.perform_later }
      expect(Rails.logger).to have_received(:info).with(/started at/).once
      expect(Rails.logger).to have_received(:info).with(/ended at/).once
    end

    it 'exposes the job_id in Current during perform' do
      job = ChildJob.perform_later
      perform_enqueued_jobs
      expect(ChildJob.current_job_id).to eq(job.job_id)
    end
  end

  class ChildJob < ApplicationJob
    class << self
      attr_accessor :current_job_id
    end

    def perform
      self.class.current_job_id = Current.job_id
    end
  end
end
