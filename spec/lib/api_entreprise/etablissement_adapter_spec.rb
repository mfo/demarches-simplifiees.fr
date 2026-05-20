# frozen_string_literal: true

describe APIEntreprise::EtablissementAdapter do
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }

  before do
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  context 'SIRET valide avec infos diffusables' do
    let(:siret) { '30613890001294' }
    let(:fixture) { 'spec/fixtures/files/api_entreprise/etablissements.json' }
    subject { described_class.new(siret, procedure_id).to_params }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/insee\/sirene\/etablissements\/#{siret}/)
        .to_return(body: File.read(fixture, status: 200))
    end

    it '#to_params class est une Hash ?' do
      expect(subject).to be_success
      expect(subject.value!).to be_a_instance_of(Hash)
    end

    context 'Attributs Etablissements' do
      it "L'entreprise contient bien un siret" do
        expect(subject.value![:siret]).to eq(siret)
      end

      it "L'entreprise contient bien un siege_social" do
        expect(subject.value![:siege_social]).to eq(true)
      end

      it "L'entreprise contient bien un naf (NAFRev2 rétrocompat)" do
        expect(subject.value![:naf]).to eq('8411Z')
      end

      it "L'entreprise contient bien un libelle_naf (NAFRev2 rétrocompat)" do
        expect(subject.value![:libelle_naf]).to eq('Administration publique générale')
      end

      it "L'entreprise contient bien un naf_2025" do
        expect(subject.value![:naf_2025]).to eq('84.11')
      end

      it "L'entreprise contient bien un libelle_naf_2025" do
        expect(subject.value![:libelle_naf_2025]).to eq('Administration publique générale')
      end

      it "L'entreprise contient bien un diffusable_commercialement qui vaut true" do
        expect(subject.value![:diffusable_commercialement]).to eq(true)
      end

      context 'Concaténation lignes adresse' do
        it "L'entreprise contient bien une adresse sur plusieurs lignes" do
          expect(subject.value![:adresse]).to eq("DIRECTION INTERMINISTERIELLE DU NUMERIQUE\r\nJEAN MARIE DURAND\r\nZAE SAINT GUENAULT\r\n51 BIS RUE DE LA PAIX\r\nCS 72809\r\n75256 PARIX CEDEX 12\r\nFRANCE")
        end
      end

      context 'Détails adresse' do
        it "L'entreprise contient bien un numero_voie" do
          expect(subject.value![:numero_voie]).to eq('22')
        end

        it "L'entreprise contient bien un type_voie" do
          expect(subject.value![:type_voie]).to eq('RUE')
        end

        it "L'entreprise contient bien un nom_voie" do
          expect(subject.value![:nom_voie]).to eq('DE LA PAIX')
        end

        it "L'entreprise contient bien un complement_adresse" do
          expect(subject.value![:complement_adresse]).to eq('ZAE SAINT GUENAULT')
        end

        it "L'entreprise contient bien un code_postal" do
          expect(subject.value![:code_postal]).to eq('75016')
        end

        it "L'entreprise contient bien une localite" do
          expect(subject.value![:localite]).to eq('PARIS 12')
        end

        it "L'entreprise ne contient pas de nom de pays" do
          expect(subject.value![:nom_pays]).to be_nil
        end

        it "L'entreprise contient bien un code_insee_localite" do
          expect(subject.value![:code_insee_localite]).to eq('75112')
        end
      end

      context 'Détails adresse étranger' do
        let(:fixture) { 'spec/fixtures/files/api_entreprise/etablissements-uk.json' }

        it "L'entreprise contient bien une localite" do
          expect(subject.value![:localite]).to eq('LONDRES')
        end

        it "L'entreprise contient bien un nom de pays" do
          expect(subject.value![:nom_pays]).to eq('ROYAUME-UNI')
        end
      end
    end

    context 'Attributs Entreprise (extraits de unite_legale)' do
      it 'contient le siren' do
        expect(subject.value![:entreprise_siren]).to eq('130025265')
      end

      it 'contient le siret_siege_social' do
        expect(subject.value![:entreprise_siret_siege_social]).to eq('13002526500013')
      end

      it 'contient la raison_sociale' do
        expect(subject.value![:entreprise_raison_sociale]).to eq('DIRECTION INTERMINISTERIELLE DU NUMERIQUE')
      end

      it 'contient la forme_juridique' do
        expect(subject.value![:entreprise_forme_juridique]).to eq("Service central d\u2019un ministère")
      end

      it 'contient le forme_juridique_code' do
        expect(subject.value![:entreprise_forme_juridique_code]).to eq('7120')
      end

      it 'contient le code_effectif_entreprise' do
        expect(subject.value![:entreprise_code_effectif_entreprise]).to eq('51')
      end

      it "contient l'etat_administratif" do
        expect(subject.value![:entreprise_etat_administratif]).to eq('actif')
      end

      it 'contient la date_creation' do
        expect(subject.value![:entreprise_date_creation]).to eq(Time.zone.at(1634103818).to_datetime)
      end

      it 'contient le nom (personne physique)' do
        expect(subject.value![:entreprise_nom]).to eq('Dupont (Martin)')
      end

      it 'contient le prenom (personne physique)' do
        expect(subject.value![:entreprise_prenom]).to eq('Jean')
      end
    end

    context 'Attributs Etablissements pour etablissement non siege' do
      let(:siret) { '17310120500719' }
      let(:fixture) { 'spec/fixtures/files/api_entreprise/etablissements-non-siege.json' }
      it "L'entreprise contient bien un siret" do
        expect(subject.value![:siret]).to eq(siret)
      end

      it "L'etablissement contient bien un siege_social à false" do
        expect(subject.value![:siege_social]).to eq(false)
      end

      it "L'etablissement contient bien une enseigne" do
        expect(subject.value![:enseigne]).to eq("SERVICE PENITENTIAIRE D'INSERTION ET DE PROBATION, DE LA HAUTE-GARONNE")
      end
    end
  end

  context 'SIRET valide avec infos non diffusables' do
    let(:siret) { '41816609600051' }
    subject { described_class.new(siret, procedure_id).to_params }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/insee\/sirene\/etablissements\/#{siret}/)
        .to_return(body: File.read('spec/fixtures/files/api_entreprise/etablissements_private.json', status: 200))
    end

    it "L'entreprise contient bien un diffusable_commercialement qui vaut false" do
      expect(subject.value![:diffusable_commercialement]).to eq(false)
    end
  end

  context 'when siret is not found' do
    let(:bad_siret) { 11_111_111_111_111 }
    subject { described_class.new(bad_siret, procedure_id).to_params }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/insee\/sirene\/etablissements\/#{bad_siret}/)
        .to_return(body: 'Fake body', status: 404)
    end

    it 'returns a Success with empty hash' do
      expect(subject).to be_success
      expect(subject.value!).to eq({})
    end
  end
end
