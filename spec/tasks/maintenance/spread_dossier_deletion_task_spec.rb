# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe SpreadDossierDeletionTask do
    describe "#process" do
      let(:dossiers) { Dossier.all }
      before do
        create(:dossier, termine_close_to_expiration_notice_sent_at: Maintenance::SpreadDossierDeletionTask::ERROR_OCCURED_AT + 1.hour)
        create(:dossier, termine_close_to_expiration_notice_sent_at: Maintenance::SpreadDossierDeletionTask::ERROR_OCCURED_AT + 2.hours)
        create(:dossier, termine_close_to_expiration_notice_sent_at: Maintenance::SpreadDossierDeletionTask::ERROR_OCCURED_AT + 3.hours)
        create(:dossier, termine_close_to_expiration_notice_sent_at: Maintenance::SpreadDossierDeletionTask::ERROR_OCCURED_AT + 4.hours)
        # Stub random_date_spread to return a value that guarantees dossiers
        # are moved outside ERROR_OCCURED_RANGE. When rand returns 1,
        # ERROR_OCCURED_AT + 1.day (= Date.new(2024, 2, 15)) stored as a
        # timestamp in Paris timezone becomes 2024-02-14 23:00:00 UTC, which
        # is still inside the range col < '2024-02-15' in PostgreSQL.
        allow_any_instance_of(described_class).to receive(:random_date_spread).and_return(2)
      end
      subject(:process) { described_class.process(dossiers) }

      it "works" do
        expect { subject }.to change { Dossier.where(termine_close_to_expiration_notice_sent_at: Maintenance::SpreadDossierDeletionTask::ERROR_OCCURED_RANGE).count }
          .from(4).to(0)
      end
    end
  end
end
