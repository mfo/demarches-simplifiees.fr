# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260528ResetEnConstructionExpirationTask do
    let(:procedure) { create(:procedure, :published) }

    describe "#collection" do
      let!(:en_construction) { create(:dossier, :en_construction, procedure:) }
      let!(:notification) do
        create(:dossier_notification, dossier: en_construction, notification_type: :dossier_expirant)
      end
      let!(:other_notification) do
        create(:dossier_notification, dossier: en_construction, notification_type: :dossier_modifie)
      end
      let!(:termine) { create(:dossier, :accepte, procedure:) }
      let!(:termine_notification) do
        create(:dossier_notification, dossier: termine, notification_type: :dossier_expirant)
      end

      it "targets only dossier_expirant notifications on en_construction dossiers" do
        ids = described_class.new.collection.flat_map { it.pluck(:id) }
        expect(ids).to contain_exactly(notification.id)
      end
    end

    describe "#process" do
      let(:dossier) { create(:dossier, :en_construction, procedure:) }
      let!(:notification) do
        create(:dossier_notification, dossier:, notification_type: :dossier_expirant)
      end
      let(:batch) { DossierNotification.where(id: notification.id) }

      it "deletes the dossier_expirant notifications in the batch" do
        expect { described_class.process(batch) }
          .to change { DossierNotification.exists?(notification.id) }.from(true).to(false)
      end
    end
  end
end
