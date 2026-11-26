# frozen_string_literal: true

RSpec.describe Mutations::DemarcheSupprimerChamp, type: :graphql do
  let(:admin) { administrateurs.default }
  let(:procedure) do
    create(:procedure, administrateurs: [admin], public_type_de_champs: [
      { type: :integer_number, libelle: 'age' },
      { type: :repetition, libelle: 'enfants', children: [{ libelle: 'prénom' }] },
      { type: :yes_no, libelle: 'boursier' },
    ])
  end
  let(:context) { { administrateur_id: admin.id, procedure_ids: admin.procedure_ids, write_access: true, remote_ip: '192.168.1.23' } }
  let(:champ_id) { id('enfants') }
  let(:query) do
    <<~GRAPHQL
      mutation($input: DemarcheSupprimerChampInput!) {
        demarcheSupprimerChamp(input: $input) {
          demarche { number }
          errors { message }
        }
      }
    GRAPHQL
  end

  subject { API::V2::Schema.execute(query, variables: { input: { demarche: { number: procedure.id }, champId: champ_id } }, context:) }

  let(:data) { subject['data']['demarcheSupprimerChamp'].deep_symbolize_keys }

  def tdc(libelle) = procedure.draft_revision.reload.type_de_champs.find { it.libelle == libelle }
  def id(libelle) = tdc(libelle).to_typed_id
  def public_libelles = procedure.draft_revision.reload.public_root_type_de_champs.map(&:libelle)

  before { procedure }

  it 'removes the champ with its children' do
    expect(data).to eq(demarche: { number: procedure.id }, errors: nil)
    expect(public_libelles).to eq(['age', 'boursier'])
  end

  context 'with an invalid id' do
    let(:champ_id) { 'not-an-id' }

    it { expect(data[:errors]).to eq([{ message: "L'identifiant de champ \"not-an-id\" est invalide." }]) }
  end

  context 'with the id of another kind of object' do
    let(:champ_id) { GraphQL::Schema::UniqueWithinType.encode('Dossier', 1) }

    it { expect(data[:errors].first[:message]).to include('est invalide') }
  end

  context 'with a champ of nowhere' do
    let(:champ_id) { GraphQL::Schema::UniqueWithinType.encode('Champ', 0) }

    it { expect(data[:errors].first[:message]).to include('n’existe pas dans le brouillon') }
  end

  context 'when a condition reads the champ' do
    let(:champ_id) { id('age') }

    before { tdc('boursier').update!(condition: Logic::Eq.new(Logic::ChampValue.new(tdc('age').stable_id), Logic::Constant.new(18))) }

    it 'is refused' do
      expect(data[:errors].first[:message]).to include('« boursier »')
      expect(public_libelles).to include('age')
    end
  end

  context 'when the champ is locked by an ineligibility rule' do
    let(:champ_id) { id('boursier') }

    before do
      procedure.draft_revision.update!(ineligibilite_enabled: true, ineligibilite_message: 'Inéligible',
        ineligibilite_rules: Logic::Eq.new(Logic::ChampValue.new(tdc('boursier').stable_id), Logic::Constant.new(true)))
    end

    it 'is refused' do
      expect(data[:errors].first[:message]).to include('boursier')
      expect(public_libelles).to include('boursier')
    end
  end

  context 'on a démarche of another administrateur' do
    let(:context) { super().merge(procedure_ids: []) }

    it 'is refused' do
      expect(data).to eq(demarche: nil, errors: [{ message: I18n.t('graphql.mutations.demarche_brouillon.demarche_not_found', number: procedure.id) }])
      expect(public_libelles).to include('enfants')
    end
  end

  context 'with a token without write access' do
    let(:context) { super().merge(write_access: false) }

    it 'is refused' do
      expect(data[:errors]).to eq([{ message: 'Le jeton utilisé est configuré seulement en lecture' }])
      expect(public_libelles).to include('enfants')
    end
  end
end
