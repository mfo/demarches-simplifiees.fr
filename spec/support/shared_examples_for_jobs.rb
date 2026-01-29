# frozen_string_literal: true

RSpec.shared_examples 'a job retrying transient errors' do |job_class = described_class|
  ExconErrorJob = Class.new(job_class) do
    def perform
      raise Excon::Error::InternalServerError, 'msg'
    end
  end if !defined?(ExconErrorJob)

  context 'when a transient network error is raised' do
    it 'makes 5 attempts before raising the exception up' do
      assert_performed_jobs 5 do
        ExconErrorJob.perform_later rescue Excon::Error::InternalServerError
      end
    end
  end
end

RSpec.shared_examples 'a job retrying standard errors' do |job_class = described_class|
  StandardErrorJob = Class.new(job_class) do
    def perform
      raise StandardError
    end
  end if !defined?(StandardErrorJob)

  context 'when another type of error is raised' do
    it 'makes 25 attempts before raising the exception up (default strategy)' do
      assert_performed_jobs 25 do
        StandardErrorJob.perform_later rescue StandardError
      end
    end
  end
end
