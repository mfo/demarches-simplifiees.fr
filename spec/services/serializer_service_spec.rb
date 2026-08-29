# frozen_string_literal: true

describe SerializerService do
  let(:procedure) { create(:procedure, :for_individual, public_type_de_champs: [{ type: :siret }]) }
  let(:dossier) { create(:dossier, :en_construction, :with_individual, :with_populated_champs, procedure:) }
  let(:champ) { dossier.champ_data.first }
  let(:etablissement) { champ.etablissement }

  describe 'dossier' do
    let(:dossier) { dossiers.en_construction }

    subject { SerializerService.dossier(dossier) }

    it 'serializes the dossier with its champs, annotations and avis but no transient URLs' do
      expect(subject).to include('number' => dossier.id, 'state' => 'en_construction')
      expect(subject.keys).to include('champs', 'annotations', 'avis', 'demandeur', 'demarche')
      expect(subject).not_to have_key('pdf')
      expect(subject.to_json).not_to include('"url"')
    end
  end

  describe 'avis' do
    let(:pending_avis) { avis.pending }

    subject { SerializerService.avis(pending_avis) }

    it { is_expected.to include('id' => pending_avis.to_typed_id, 'question' => pending_avis.introduction) }
  end

  describe 'message' do
    let(:commentaire) { dossiers.en_construction.commentaires.first }

    subject { SerializerService.message(commentaire) }

    it { is_expected.to include('id' => commentaire.to_typed_id, 'body' => commentaire.body) }
  end

  describe 'champ' do
    subject { SerializerService.champ(champ) }

    describe 'type champ is siret' do
      it '', :slow do
        is_expected.to include("stringValue" => etablissement.siret)
        expect(subject["etablissement"]).to include("siret" => etablissement.siret)
        expect(subject["etablissement"]["entreprise"]).to include("codeEffectifEntreprise" => etablissement.entreprise_code_effectif_entreprise)
      end

      context 'with entreprise_date_creation is nil' do
        before { etablissement.update(entreprise_date_creation: nil) }

        it {
          expect(subject["etablissement"]["entreprise"]).to include("nomCommercial" => etablissement.entreprise_nom_commercial)
          expect(subject["etablissement"]["entreprise"]["dateCreation"]).to be_nil
        }
      end
    end
  end
end
