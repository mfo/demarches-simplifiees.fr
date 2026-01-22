# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260120fixRestoredDossiersThatRemainExpiredTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let!(:dossier_expired) { create(:dossier, hidden_by_expired_at: Time.zone.now, hidden_by_reason: "expired") }
      let!(:dossier_expired_and_then_restored) { create(:dossier, hidden_by_expired_at: Time.zone.now, hidden_by_reason: nil) }

      it do
        expect(collection).to include(dossier_expired_and_then_restored)
        expect(collection).not_to include (dossier_expired)
      end
    end

    describe "#process" do
      let!(:procedure) { create(:procedure, duree_conservation_dossiers_dans_ds: 6) }

      subject(:process) { described_class.process(dossier) }

      before { dossier.update_expired_at }

      context "when the dossier was due to expire less than a month ago" do
        let!(:dossier) { create(:dossier, :accepte, procedure:, processed_at: 6.months.ago, termine_close_to_expiration_notice_sent_at: 2.weeks.ago, hidden_by_expired_at: Time.zone.now) }

        it do
          subject

          expect(dossier.hidden_by_expired_at).to eq(nil)
          expect(dossier.termine_close_to_expiration_notice_sent_at).to eq(nil)
          expect(dossier.conservation_extension).to eq(1.month)
          expect(dossier.expired_at.to_date).to eq(1.month.from_now.to_date)
        end
      end

      context "when the dossier was due to expire over a month ago" do
        let!(:dossier) { create(:dossier, :accepte, procedure:, processed_at: 8.months.ago, termine_close_to_expiration_notice_sent_at: (2.months + 2.weeks).ago, hidden_by_expired_at: 2.months.ago) }

        it do
          subject

          expect(dossier.hidden_by_expired_at).to eq(nil)
          expect(dossier.termine_close_to_expiration_notice_sent_at).to eq(nil)
          expect(dossier.conservation_extension).to eq(3.months)
          expect(dossier.expired_at.to_date).to eq(1.month.from_now.to_date)
        end
      end

      context "when the dossier has already had a conservation extension" do
        let!(:dossier) { create(:dossier, :accepte, procedure:, processed_at: 7.months.ago, conservation_extension: 1.month, termine_close_to_expiration_notice_sent_at: 2.weeks.ago, hidden_by_expired_at: Time.zone.now) }

        it do
          subject

          expect(dossier.hidden_by_expired_at).to eq(nil)
          expect(dossier.termine_close_to_expiration_notice_sent_at).to eq(nil)
          expect(dossier.conservation_extension).to eq(2.months)
          expect(dossier.expired_at.to_date).to eq(1.month.from_now.to_date)
        end
      end
    end
  end
end
