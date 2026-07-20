# frozen_string_literal: true

RSpec.describe DossierMessagerieConcern do
  describe '.with_unread_messages_for_user' do
    subject { Dossier.with_unread_messages_for_user }

    context 'when an agent sent an unread message' do
      let!(:dossier) { create(:dossier, :en_construction) }

      before { create(:commentaire, dossier:, instructeur: create(:instructeur), seen_by_recipient_at: nil) }

      it { is_expected.to include(dossier) }
    end

    context 'when the agent message has been seen' do
      let!(:dossier) { create(:dossier, :en_construction) }

      before { create(:commentaire, dossier:, instructeur: create(:instructeur), seen_by_recipient_at: 1.day.ago) }

      it { is_expected.not_to include(dossier) }
    end

    context 'when the message was sent by the usager' do
      let!(:dossier) { create(:dossier, :en_construction) }

      before { create(:commentaire, dossier:, seen_by_recipient_at: nil) }

      it { is_expected.not_to include(dossier) }
    end

    context 'when the dossier is pending_correction' do
      let!(:dossier) { create(:dossier, :en_construction) }

      before do
        create(:commentaire, dossier:, instructeur: create(:instructeur), seen_by_recipient_at: nil)
        create(:dossier_correction, dossier:)
      end

      it 'excludes it (the badge shown is « à corriger », not « nouveau message »)' do
        is_expected.not_to include(dossier)
      end
    end

    context 'when the dossier is pending_response' do
      let!(:dossier) { create(:dossier, :en_construction) }

      before do
        create(:commentaire, dossier:, instructeur: create(:instructeur), seen_by_recipient_at: nil)
        create(:dossier_pending_response, dossier:)
      end

      it 'excludes it (the badge shown is « en attente de réponse », not « nouveau message »)' do
        is_expected.not_to include(dossier)
      end
    end
  end
end
