# frozen_string_literal: true

describe TypesDeChamp::PreRempliTypeDeChamp do
  let(:types_de_champ_public) { [{ type: :pre_rempli }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first }
  let(:type_de_champ) { champ.type_de_champ }

  describe '#tags_for_template' do
    it 'returns tags with libelle' do
      tags = type_de_champ.tags_for_template
      expect(tags).to be_an(Array)
      expect(tags.first[:libelle]).to include(type_de_champ.libelle)
    end
  end
end
