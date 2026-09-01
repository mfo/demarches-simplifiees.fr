# frozen_string_literal: true

describe Champs::FranceConnectChamp, type: :model do
  describe "quotient familial champ" do
    let(:public_type_de_champs) { [{ type: :quotient_familial }] }
    let(:procedure) { create(:procedure, public_type_de_champs:, for_individual: true) }
    let(:dossier) { create(:dossier, procedure:, for_tiers: false, for_procedure_preview: false) }
    let(:champ) { dossier.champ_data.first }
    let!(:fci) { create(:france_connect_information, user: dossier.user) }

    describe '#ready_for_external_call?' do
      subject { champ.ready_for_external_call? }

      it do
        is_expected.to be_truthy
      end

      context 'when dossier is for procedure preview' do
        before { dossier.update(for_procedure_preview: true) }

        it do
          is_expected.to be_falsey
        end
      end

      context 'when procedure is not for individual' do
        before do
          procedure.update(for_individual: false)
          dossier.reload
        end

        it do
          is_expected.to be_falsey
        end
      end

      context 'when dossier is for tiers' do
        before { dossier.update(for_tiers: true) }

        it do
          is_expected.to be_falsey
        end
      end

      context 'when user has never logged in with FC' do
        let!(:fci) {}
        it 'set recovered_qf_data to false' do
          expect(dossier.user_from_france_connect?).to eq(false)
          is_expected.to be_falsey
        end
      end
    end
  end

  describe '#fc_data_not_found?' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :aah }], for_individual: true) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champ_data.first }

    subject { champ.fc_data_not_found? }

    before { champ.external_state = 'external_error' }

    context 'with a 404 exception' do
      before { champ.fetch_external_data_exceptions = [ExternalDataException.new(error: 'NotFound', code: 404)] }

      it { is_expected.to be_truthy }
    end

    context 'without recorded exceptions' do
      before { champ.fetch_external_data_exceptions = nil }

      it { is_expected.to be_falsey }
    end
  end

  describe '#libelle' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :aah }], for_individual: true) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champ_data.first }

    subject { champ.libelle }

    context 'when data has not been fetched' do
      before { champ.update(external_state: 'idle') }

      it 'keeps the acronym untouched' do
        is_expected.to eq('Justificatif de statut allocation adulte handicapé (AAH)')
      end
    end

    context 'when data is being fetched' do
      before { champ.update(external_state: 'waiting_for_job') }

      it 'keeps the acronym untouched' do
        is_expected.to eq('Statut allocation adulte handicapé (AAH) (France Connect)')
      end
    end
  end
end
