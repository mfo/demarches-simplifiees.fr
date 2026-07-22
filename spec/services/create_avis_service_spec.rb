# frozen_string_literal: true

describe CreateAvisService do
  let(:instructeur) { instructeurs.default }
  let(:procedure) { procedures.individual }
  let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure:) }
  let(:expert_email) { 'expert@exemple.fr' }

  subject(:result) do
    avis = Avis.new(introduction: 'Merci de donner votre avis.', dossier:)
    CreateAvisService.call(
      claimant: instructeur,
      batch: true,
      avis:,
      emails: [expert_email]
    )
  end

  describe '#call' do
    context 'when everything goes well' do
      it 'creates an avis for the dossier' do
        expect { result }.to change { dossier.avis.count }.by(1)
      end
    end

    context 'when the procedure restricts experts to administrateur invitations' do
      let(:procedure) { create(:simple_procedure, experts_require_administrateur_invitation: true, instructeurs: [instructeur]) }

      context 'and the email is in the administrateur-approved list' do
        let(:invited_expert) { create(:expert) }
        let!(:invited_ep) { create(:experts_procedure, procedure:, expert: invited_expert) }
        let(:expert_email) { invited_expert.email }

        it 'creates the avis' do
          sent_emails, failed_emails = result
          expect(sent_emails).to eq([invited_expert.email])
          expect(failed_emails).to be_empty
          expect(dossier.avis.count).to eq(1)
        end
      end

      context 'and the email is not in the administrateur-approved list' do
        let(:expert_email) { 'rogue@example.fr' }

        it 'rejects the email and does not create user, expert, or avis' do
          sent_emails, failed_emails = result
          expect(sent_emails).to be_empty
          expect(failed_emails).to contain_exactly(hash_including(email: 'rogue@example.fr'))
          expect(dossier.avis.count).to eq(0)
          expect(User.find_by(email: 'rogue@example.fr')).to be_nil
        end
      end
    end
  end
end
