# frozen_string_literal: true

describe TransientModelsWithPurgeableJobConcern do
  describe '#compute_with_safe_stale_for_purge' do
    let(:archive) { create(:archive, :generated) }

    it 'returns without re-running the block when already generated' do
      expect { |b| archive.compute_with_safe_stale_for_purge(&b) }.not_to yield_control
      expect(archive.reload).to be_generated
    end
  end
end
