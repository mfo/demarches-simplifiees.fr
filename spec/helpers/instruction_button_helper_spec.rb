# frozen_string_literal: true

describe InstructionButtonHelper, type: :helper do
  describe '#invalid_annotations_libelles' do
    let(:procedure) { create(:procedure, :published, private_type_de_champs: [{ type: :text, libelle: 'Appréciation globale', mandatory: true }]) }
    let(:dossier) { create(:dossier, :en_instruction, procedure:) }

    it 'returns libelles of invalid private champs' do
      dossier.champs_private_valid?
      expect(helper.invalid_annotations_libelles(dossier)).to eq(['Appréciation globale'])
    end
  end
end
