# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260601NullifyEnConstructionExpiredAtTask do
    let(:procedure) { create(:procedure, :published) }

    describe "#collection" do
      empty_seeds Dossier

      let!(:en_construction_with_expired_at) { create(:dossier, :en_construction, procedure:) }
      let!(:en_construction_clean) do
        create(:dossier, :en_construction, procedure:).tap { it.update_column(:expired_at, nil) }
      end
      let!(:brouillon_with_expired_at) { create(:dossier, procedure:) }
      let!(:termine_with_expired_at) { create(:dossier, :accepte, procedure:) }

      it "targets only en_construction dossiers with a non-null expired_at" do
        ids = described_class.new.collection.flat_map { it.pluck(:id) }
        expect(ids).to contain_exactly(en_construction_with_expired_at.id)
      end
    end

    describe "#process" do
      let!(:dossier) { create(:dossier, :en_construction, procedure:) }
      let(:batch) { Dossier.where(id: dossier.id) }

      it "nullifies expired_at for the batch" do
        expect { described_class.process(batch) }
          .to change { dossier.reload.expired_at }.to(nil)
      end
    end
  end
end
