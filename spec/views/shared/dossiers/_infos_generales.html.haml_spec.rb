# frozen_string_literal: true

describe 'shared/dossiers/_infos_generales', type: :view do
  let(:dossier) { create(:dossier, :en_construction) }
  before do
    sign_in(current_role.user)
    allow(view).to receive(:current_instructeur).and_return(current_role)
    allow(view).to receive(:dossier).and_return(dossier)
  end

  context 'when expert' do
    let(:current_role) { create(:expert) }
    subject { render 'shared/dossiers/infos_generales', dossier: dossier, profile: 'expert' }

    context 'with an attestation' do
      let(:dossier) { create :dossier, :accepte, :with_attestation_acceptation }

      it 'provides a link to the attestation' do
        expect(subject).to have_text('Attestation')
      end
    end
  end

  context 'when instructeur' do
    let(:current_role) { create(:instructeur) }
    subject { render 'shared/dossiers/infos_generales', dossier: dossier, profile: 'instructeur' }

    context 'with a motivation' do
      let(:dossier) { create :dossier, :accepte, :with_motivation }

      it 'does not display the motivation (moved to suivi_et_decision)' do
        expect(subject).not_to have_content(dossier.motivation)
      end
    end

    context 'with a motivation and procedure with accuse de lecture' do
      let(:dossier) { create :dossier, :accepte, :with_motivation, procedure: create(:procedure, :accuse_lecture) }

      it 'does not display the motivation (moved to suivi_et_decision)' do
        expect(subject).not_to have_content(dossier.motivation)
      end
    end

    context 'with an attestation' do
      let(:dossier) { create :dossier, :accepte, :with_attestation_acceptation }

      it 'does not display the attestation (moved to suivi_et_decision)' do
        expect(subject).not_to have_text('Attestation')
      end
    end

    context 'with a justificatif' do
      let(:dossier) do
        dossier = create(:dossier, :accepte, :with_justificatif)
        dossier.justificatif_motivation.blob.update(virus_scan_result: ActiveStorage::VirusScanner::SAFE)
        dossier
      end

      it 'does not display the justificatif (moved to suivi_et_decision)' do
        expect(subject).not_to have_css("a[href*='/rails/active_storage/blobs/']")
      end
    end
  end
end
