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
        expect(described_class.new.collection).to contain_exactly(notification)
      end
    end

    describe "#process" do
      let(:dossier) { create(:dossier, :en_construction, procedure:) }
      let!(:notification) do
        create(:dossier_notification, dossier:, notification_type: :dossier_expirant)
      end

      it "destroys the dossier_expirant notification" do
        expect { described_class.process(notification) }
          .to change { DossierNotification.exists?(notification.id) }.from(true).to(false)
      end
    end
  end
end
