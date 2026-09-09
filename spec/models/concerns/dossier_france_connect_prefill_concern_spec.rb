# frozen_string_literal: true

describe DossierFranceConnectPrefillConcern do
  describe '#prefill_champs_from_france_connect' do
    let_it_be(:procedure) { create(:procedure, :for_individual, public_type_de_champs: [{ type: :date }]) }
    let(:user) { create(:user, france_connect_informations: [build(:france_connect_information)]) }
    let(:dossier) { create(:dossier, procedure:, user:) }
    let(:tdc) { procedure.active_revision.public_root_type_de_champs.first }

    before do
      tdc.update!(options: { 'birthdate' => '1', 'prefill_with_france_connect_information' => '1' })
    end

    subject { dossier.prefill_champs_from_france_connect(updated_by: user.email) }

    it 'prefills the date champ with the FranceConnect birthdate' do
      subject
      champ = dossier.reload.project_champ(tdc)
      expect(champ.value).to eq('1976-02-24')
      expect(champ.data['prefilled_from_france_connect_information']).to be true
    end

    context 'when the champ already has a value' do
      before do
        champ = dossier.project_champ(tdc)
        champ.value = '2000-01-01'
        champ.save!
      end

      it 'does not overwrite' do
        subject
        expect(dossier.project_champ(tdc).value).to eq('2000-01-01')
      end
    end

    context 'when the option is not enabled on the tdc' do
      before { tdc.update!(options: { 'birthdate' => '1', 'prefill_with_france_connect_information' => '0' }) }

      it 'does not prefill' do
        subject
        expect(dossier.project_champ(tdc).value).to be_blank
      end
    end

    context 'when the dossier is for_tiers' do
      before { dossier.update_columns(for_tiers: true) }

      it 'does not prefill' do
        subject
        expect(dossier.project_champ(tdc).value).to be_blank
      end
    end

    context 'when the user has no FranceConnect information' do
      let(:user) { users.usager }

      it 'does not prefill' do
        subject
        expect(dossier.project_champ(tdc).value).to be_blank
      end
    end

    context 'clears the prefilled_from_france_connect_information flag if the user later modifies the value' do
      it do
        subject
        champ = dossier.reload.project_champ(tdc)
        champ.value = '2010-05-15'
        champ.save!
        expect(champ.reload.data['prefilled_from_france_connect_information']).to be_nil
      end
    end
  end
end
