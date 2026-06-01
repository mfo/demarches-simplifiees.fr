# frozen_string_literal: true

describe ChampPrefillTrackingConcern do
  let(:types_de_champ_public) { [{ type: :text }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first }

  describe '#prefilled_value_modified?' do
    context 'when champ is not prefilled' do
      it 'returns false' do
        champ.update!(value: 'hello')
        expect(champ.prefilled_value_modified?).to be false
      end
    end

    context 'when champ is prefilled but not modified' do
      before do
        champ.update!(prefilled: true, value: 'original', prefilled_original_value: { 'value' => 'original' })
      end

      it 'returns false' do
        expect(champ.prefilled_value_modified?).to be false
      end
    end

    context 'when champ is prefilled and value differs' do
      before do
        champ.update!(prefilled: true, value: 'modified', prefilled_original_value: { 'value' => 'original' })
      end

      it 'returns true' do
        expect(champ.prefilled_value_modified?).to be true
      end
    end

    context 'when champ is prefilled and cleared by user' do
      before do
        champ.update!(prefilled: true, value: nil, prefilled_original_value: { 'value' => 'original' })
      end

      it 'returns true' do
        expect(champ.prefilled_value_modified?).to be true
      end
    end
  end

  describe '#revert_to_prefilled_value!' do
    context 'with a value-based champ' do
      before do
        champ.update!(prefilled: true, value: 'modified', prefilled_original_value: { 'value' => 'original' })
      end

      it 'restores the original value' do
        champ.revert_to_prefilled_value!
        expect(champ.reload.value).to eq('original')
      end

      it 'makes prefilled_value_modified? return false' do
        champ.revert_to_prefilled_value!
        expect(champ.reload.prefilled_value_modified?).to be false
      end
    end

    context 'with an external_id-based champ' do
      before do
        champ.update!(prefilled: true, external_id: 'modified_id', prefilled_original_value: { 'external_id' => 'original_id' })
      end

      it 'restores the original external_id' do
        champ.revert_to_prefilled_value!
        expect(champ.reload.external_id).to eq('original_id')
      end
    end
  end
end
