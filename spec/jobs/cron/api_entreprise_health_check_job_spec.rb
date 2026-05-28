# frozen_string_literal: true

RSpec.describe Cron::APIEntrepriseHealthCheckJob, type: :job do
  describe '#perform' do
    it 'refreshes all provider statuses' do
      expect(APIEntreprise::HealthChecker).to receive(:refresh_all!)
      described_class.perform_now
    end
  end
end
