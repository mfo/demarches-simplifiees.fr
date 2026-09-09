# frozen_string_literal: true

describe DossierMessagerieConcern do
  describe '.with_unread_messages_for_user' do
    let_it_be(:dossier_with_unread_instructeur) { create(:dossier, :en_construction, procedure: procedures.individual) }
    let_it_be(:dossier_with_read_instructeur) { create(:dossier, :en_construction, procedure: procedures.individual) }
    let_it_be(:dossier_with_unread_expert) { create(:dossier, :en_construction, procedure: procedures.individual) }
    let_it_be(:dossier_with_only_usager_message) { create(:dossier, :en_construction, procedure: procedures.individual) }
    let_it_be(:dossier_with_discarded_unread) { create(:dossier, :en_construction, procedure: procedures.individual) }
    let_it_be(:dossier_with_pending_correction) { create(:dossier, :en_construction, procedure: procedures.individual) }
    let_it_be(:dossier_with_pending_response) { create(:dossier, :en_construction, procedure: procedures.individual) }

    before_all do
      create(:commentaire, dossier: dossier_with_unread_instructeur, instructeur: instructeurs.default, seen_by_recipient_at: nil)
      create(:commentaire, dossier: dossier_with_read_instructeur, instructeur: instructeurs.default, seen_by_recipient_at: 1.day.ago)
      create(:commentaire, dossier: dossier_with_unread_expert, expert: experts.default, seen_by_recipient_at: nil)
      create(:commentaire, dossier: dossier_with_only_usager_message, seen_by_recipient_at: nil)
      create(:commentaire, dossier: dossier_with_discarded_unread, instructeur: instructeurs.default, seen_by_recipient_at: nil, discarded_at: Time.current)
      create(:commentaire, dossier: dossier_with_pending_correction, instructeur: instructeurs.default, seen_by_recipient_at: nil)
      create(:dossier_correction, dossier: dossier_with_pending_correction)
      create(:commentaire, dossier: dossier_with_pending_response, instructeur: instructeurs.default, seen_by_recipient_at: nil)
      create(:dossier_pending_response, dossier: dossier_with_pending_response)
    end

    subject { procedures.individual.dossiers.with_unread_messages_for_user }

    it 'includes dossiers with unread instructeur messages' do
      expect(subject).to include(dossier_with_unread_instructeur)
    end

    it 'includes dossiers with unread expert messages' do
      expect(subject).to include(dossier_with_unread_expert)
    end

    it 'excludes dossiers where instructeur messages are read' do
      expect(subject).not_to include(dossier_with_read_instructeur)
    end

    it 'excludes dossiers where only the usager posted a message' do
      expect(subject).not_to include(dossier_with_only_usager_message)
    end

    it 'excludes dossiers where the unread message is discarded' do
      expect(subject).not_to include(dossier_with_discarded_unread)
    end

    it 'excludes dossiers pending a correction (the « à corriger » badge takes precedence)' do
      expect(subject).not_to include(dossier_with_pending_correction)
    end

    it 'excludes dossiers pending a response (the « en attente de réponse » badge takes precedence)' do
      expect(subject).not_to include(dossier_with_pending_response)
    end

    it 'includes a dossier with an unresolved correction that is no longer en_construction (the « à corriger » badge only applies en_construction)' do
      dossier = create(:dossier, :en_instruction, procedure: procedures.individual)
      create(:commentaire, dossier:, instructeur: instructeurs.default, seen_by_recipient_at: nil)
      create(:dossier_correction, dossier:)

      expect(subject).to include(dossier)
    end
  end
end
