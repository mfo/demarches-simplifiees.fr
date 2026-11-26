# frozen_string_literal: true

RSpec.describe Mutations::DemarcheAjouterChamp, type: :graphql do
  let(:admin) { administrateurs.default }
  let(:procedure) do
    create(:procedure, administrateurs: [admin], public_type_de_champs: [
      { type: :integer_number, libelle: 'age' },
      { type: :repetition, libelle: 'enfants', children: [{ libelle: 'prénom' }] },
      { type: :yes_no, libelle: 'boursier' },
    ])
  end
  let(:context) { { administrateur_id: admin.id, procedure_ids: admin.procedure_ids, scopes: [APIToken::FORM_WRITE], remote_ip: '192.168.1.23' } }
  let(:input) { { type: 'drop_down_list', label: 'statut', required: true, apresId: id('age'), options: { drop_down_options: ['salarié', 'étudiant'] } } }
  let(:query) do
    <<~GRAPHQL
      mutation($input: DemarcheAjouterChampInput!) {
        demarcheAjouterChamp(input: $input) {
          champDescriptor { id label required __typename }
          errors { message }
        }
      }
    GRAPHQL
  end

  subject { API::V2::Schema.execute(query, variables: { input: { demarche: { number: procedure.id }, **input } }, context:) }

  let(:data) { subject['data']['demarcheAjouterChamp'].deep_symbolize_keys }

  def tdc(libelle) = procedure.draft_revision.reload.type_de_champs.find { it.libelle == libelle }
  def id(libelle) = tdc(libelle).to_typed_id
  def public_libelles = procedure.draft_revision.reload.public_root_type_de_champs.map(&:libelle)

  before { procedure }

  it 'adds the champ to the draft after the given one' do
    expect(data[:errors]).to be_nil
    expect(data[:champDescriptor]).to eq(id: id('statut'), label: 'statut', required: true, __typename: 'DropDownListChampDescriptor')
    expect(public_libelles).to eq(['age', 'statut', 'enfants', 'boursier'])
    expect(tdc('statut').drop_down_options).to eq(['salarié', 'étudiant'])
  end

  context 'without apresId' do
    let(:input) { { type: 'text', label: 'nom' } }

    it 'adds it first, and mandatory by default' do
      expect(data[:champDescriptor]).to include(label: 'nom', required: true)
      expect(public_libelles.first).to eq('nom')
    end
  end

  context 'with required false' do
    let(:input) { { type: 'text', label: 'nom', required: false } }

    it { expect(data[:champDescriptor]).to include(required: false) }
  end

  context 'with a type that cannot be mandatory' do
    let(:input) { { type: 'header_section', label: 'titre', required: true } }

    it { expect(data[:champDescriptor]).to include(label: 'titre', required: false) }
  end

  context 'as an annotation' do
    let(:input) { { type: 'text', label: 'décision', annotation: true } }

    it 'adds it to the private champs' do
      expect(data[:champDescriptor]).to include(label: 'décision', required: false)
      expect(tdc('décision')).to be_private
    end
  end

  context 'in a repetition' do
    let(:input) { { type: 'date', label: 'naissance', parentId: id('enfants'), apresId: id('prénom') } }

    it do
      expect(data[:errors]).to be_nil
      expect(tdc('enfants').flat_children.map(&:libelle)).to eq(['prénom', 'naissance'])
    end
  end

  context 'with the layers of a carte' do
    let(:input) { { type: 'carte', label: 'parcelle', options: { cadastres: true, unesco: true, znieff: true } } }

    it { expect { subject }.to change { tdc('parcelle')&.carte_optional_layers }.to([:cadastres, :unesco, :znieff]) }
  end

  context 'with a formatted champ and one option' do
    let(:input) { { type: 'formatted', label: 'code', options: { max_character_length: 5 } } }

    it 'keeps the defaults of the type' do
      expect(data[:errors]).to be_nil
      expect(tdc('code')).to have_attributes(formatted_mode: 'simple', max_character_length: 5)
    end
  end

  context 'with options of another type' do
    let(:input) { { type: 'text', label: 'nom', options: { character_limit: 10 } } }

    it 'is refused, with the reason' do
      expect(data[:champDescriptor]).to be_nil
      expect(data[:errors]).to eq([{ message: 'Options inconnues pour le type « text » : character_limit. Options acceptées : aucune.' }])
      expect(public_libelles).not_to include('nom')
    end
  end

  context 'with a header section level that does not exist' do
    let(:input) { { type: 'header_section', label: 'titre', options: { header_section_level: 9 } } }

    it 'is refused and not added' do
      expect(data[:champDescriptor]).to be_nil
      expect(data[:errors]).not_to be_empty
      expect(public_libelles).not_to include('titre')
    end
  end

  context 'when the editor would show the champ invalid' do
    let(:input) { { type: 'header_section', label: 'titre', options: { header_section_level: 2 } } }

    it 'is refused with the editor message' do
      expect(data[:errors].first[:message]).to include('« titre »', 'titre de niveau 1')
      expect(public_libelles).not_to include('titre')
    end
  end

  context 'with a type that is not enabled' do
    let(:input) { { type: 'engagement_juridique', label: 'ej', annotation: true } }

    it { expect(data[:errors].first[:message]).to include('n’est pas activé') }
  end

  context 'with an invalid id' do
    let(:input) { { type: 'text', label: 'nom', apresId: 'not-an-id' } }

    it { expect(data[:errors]).to eq([{ message: I18n.t('graphql.mutations.demarche_brouillon.invalid_champ_id', id: 'not-an-id') }]) }
  end

  context 'on a published démarche' do
    let(:procedure) { create(:procedure, :published, administrateurs: [admin], public_type_de_champs: [{ type: :integer_number, libelle: 'age' }]) }
    let(:input) { { type: 'text', label: 'nom' } }

    it 'adds to the draft only' do
      expect(data[:errors]).to be_nil
      expect(public_libelles).to eq(['nom', 'age'])
      expect(procedure.published_revision.reload.type_de_champs.map(&:libelle)).to eq(['age'])
    end
  end

  context 'on a démarche of another administrateur' do
    let(:context) { super().merge(procedure_ids: []) }

    it do
      expect(data[:errors]).to eq([{ message: I18n.t('graphql.mutations.demarche_brouillon.demarche_not_found', number: procedure.id) }])
      expect(public_libelles).to eq(['age', 'enfants', 'boursier'])
    end
  end

  context 'with a token without the form editing scope' do
    let(:context) { super().merge(scopes: [APIToken::APPLICATION_READ, APIToken::APPLICATION_WRITE]) }

    it do
      expect(data[:errors]).to eq([{ message: I18n.t('graphql.mutations.demarche_brouillon.form_scope_required') }])
      expect(public_libelles).to eq(['age', 'enfants', 'boursier'])
    end
  end
end
