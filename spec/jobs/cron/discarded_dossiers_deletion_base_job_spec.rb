# frozen_string_literal: true

RSpec.describe Cron::DiscardedDossiersDeletionBaseJob, type: :job do
  describe '.schedulable?' do
    it 'is false so rake jobs:schedule skips this abstract base class' do
      expect(described_class.schedulable?).to be false
    end
  end
end
