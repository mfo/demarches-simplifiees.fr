# frozen_string_literal: true

RSpec.describe Mutations::DemarcheDeplacerChamp, type: :graphql do
  let(:admin) { administrateurs.default }
  let(:procedure) do
    create(:procedure, administrateurs: [admin], public_type_de_champs: [
      { type: :integer_number, libelle: 'age' },
      { type: :repetition, libelle: 'enfants', children: [{ libelle: 'prénom' }] },
      { type: :yes_no, libelle: 'boursier' },
    ])
  end
  let(:context) { { administrateur_id: admin.id, procedure_ids: admin.procedure_ids, scopes: [APIToken::FORM_WRITE], remote_ip: '192.168.1.23' } }
  let(:champ_id) { id('boursier') }
  let(:apres_id) { nil }
  let(:query) do
    <<~GRAPHQL
      mutation($input: DemarcheDeplacerChampInput!) {
        demarcheDeplacerChamp(input: $input) {
          champDescriptor { id label }
          errors { message }
        }
      }
    GRAPHQL
  end

  subject { API::V2::Schema.execute(query, variables: { input: { demarche: { number: procedure.id }, champId: champ_id, apresId: apres_id }.compact }, context:) }

  let(:data) { subject['data']['demarcheDeplacerChamp'].deep_symbolize_keys }

  def tdc(libelle) = procedure.draft_revision.reload.type_de_champs.find { it.libelle == libelle }
  def id(libelle) = tdc(libelle).to_typed_id
  def public_libelles = procedure.draft_revision.reload.public_root_type_de_champs.map(&:libelle)

  before { procedure }

  it 'moves the champ first without apresId' do
    expect(data).to eq(champDescriptor: { id: champ_id, label: 'boursier' }, errors: nil)
    expect(public_libelles).to eq(['boursier', 'age', 'enfants'])
  end

  context 'with apresId' do
    let(:champ_id) { id('age') }
    let(:apres_id) { id('boursier') }

    it do
      expect(data[:errors]).to be_nil
      expect(public_libelles).to eq(['enfants', 'boursier', 'age'])
    end
  end

  context 'on a published démarche' do
    let(:procedure) do
      create(:procedure, :published, administrateurs: [admin], public_type_de_champs: [{ type: :integer_number, libelle: 'age' }, { type: :yes_no, libelle: 'boursier' }])
    end

    it 'moves the draft and returns the champ' do
      expect(data).to eq(champDescriptor: { id: champ_id, label: 'boursier' }, errors: nil)
      expect(public_libelles).to eq(['boursier', 'age'])
    end
  end

  context 'after itself' do
    let(:apres_id) { champ_id }

    it do
      expect(data[:errors].first[:message]).to include('après lui-même')
      expect(public_libelles).to eq(['age', 'enfants', 'boursier'])
    end
  end

  context 'after a champ of another block' do
    let(:apres_id) { id('prénom') }

    it { expect(data[:errors].first[:message]).to include('n’est pas dans le même bloc') }
  end

  context 'with an invalid apresId' do
    let(:apres_id) { 'not-an-id' }

    it { expect(data[:errors]).to eq([{ message: I18n.t('graphql.mutations.demarche_brouillon.invalid_champ_id', id: 'not-an-id') }]) }
  end

  context 'with a champ of nowhere' do
    let(:champ_id) { GraphQL::Schema::UniqueWithinType.encode('Champ', 0) }

    it { expect(data[:errors].first[:message]).to include('n’existe pas dans le brouillon') }
  end

  context 'when the move breaks a condition' do
    let(:champ_id) { id('age') }
    let(:apres_id) { id('boursier') }

    before { tdc('boursier').update!(condition: Logic::Eq.new(Logic::ChampValue.new(tdc('age').stable_id), Logic::Constant.new(18))) }

    it 'is refused and the order is kept' do
      expect(data[:errors].first[:message]).to include('« boursier »')
      expect(public_libelles).to eq(['age', 'enfants', 'boursier'])
    end
  end

  context 'on a démarche of another administrateur' do
    let(:context) { super().merge(procedure_ids: []) }

    it do
      expect(data).to eq(champDescriptor: nil, errors: [{ message: I18n.t('graphql.mutations.demarche_brouillon.demarche_not_found', number: procedure.id) }])
      expect(public_libelles).to eq(['age', 'enfants', 'boursier'])
    end
  end

  context 'with a token without the form editing scope' do
    let(:context) { super().merge(scopes: [APIToken::APPLICATION_READ, APIToken::APPLICATION_WRITE]) }

    it 'is refused' do
      expect(data[:errors]).to eq([{ message: I18n.t('graphql.mutations.demarche_brouillon.form_scope_required') }])
      expect(public_libelles).to eq(['age', 'enfants', 'boursier'])
    end
  end
end
