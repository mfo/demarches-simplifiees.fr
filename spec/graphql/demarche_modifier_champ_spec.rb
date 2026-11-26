# frozen_string_literal: true

RSpec.describe Mutations::DemarcheModifierChamp, type: :graphql do
  let(:admin) { administrateurs.default }
  let(:procedure) do
    create(:procedure, administrateurs: [admin], public_type_de_champs: [
      { type: :text, libelle: 'nom' },
      { type: :repetition, libelle: 'enfants', children: [{ libelle: 'prénom' }] },
    ])
  end
  let(:context) { { administrateur_id: admin.id, procedure_ids: admin.procedure_ids, scopes: [APIToken::FORM_WRITE], remote_ip: '192.168.1.23' } }
  let(:champ_id) { id('nom') }
  let(:input) { { label: 'nom de famille', required: false, type: 'textarea', options: { character_limit: '400' } } }
  let(:query) do
    <<~GRAPHQL
      mutation($input: DemarcheModifierChampInput!) {
        demarcheModifierChamp(input: $input) {
          champDescriptor { id label required __typename }
          errors { message }
        }
      }
    GRAPHQL
  end

  subject { API::V2::Schema.execute(query, variables: { input: { demarche: { number: procedure.id }, champId: champ_id, **input } }, context:) }

  let(:data) { subject['data']['demarcheModifierChamp'].deep_symbolize_keys }

  def tdc(libelle) = procedure.draft_revision.reload.type_de_champs.find { it.libelle == libelle }
  def id(libelle) = tdc(libelle).to_typed_id

  before { procedure }

  it 'updates the champ of the draft' do
    expect(data[:errors]).to be_nil
    expect(data[:champDescriptor]).to eq(id: id('nom de famille'), label: 'nom de famille', required: false, __typename: 'TextareaChampDescriptor')
    expect(tdc('nom de famille').options).to include('character_limit' => '400')
  end

  context 'with a type outside the matrix of a published champ' do
    before do
      procedure.publish!(admin)
    end

    let(:input) { { type: 'yes_no' } }

    it 'is refused' do
      expect(data[:errors].first[:message]).to include('« nom »', 'text')
      expect(procedure.draft_revision.reload.type_de_champs.find { it.libelle == 'nom' }.type_champ).to eq('text')
    end
  end

  context 'with a repetition that holds champs' do
    let(:champ_id) { id('enfants') }
    let(:input) { { type: 'text' } }

    it { expect(data[:errors].first[:message]).to include('« enfants »', 'bloc répétable') }
  end

  context 'with nothing to change' do
    let(:input) { {} }

    it { expect(data[:errors]).to eq([{ message: 'Aucune modification demandée.' }]) }
  end

  context 'with a champ of nowhere' do
    let(:champ_id) { GraphQL::Schema::UniqueWithinType.encode('Champ', 0) }

    it { expect(data[:errors].first[:message]).to include('n’existe pas dans le brouillon') }
  end

  context 'with an invalid champId' do
    let(:champ_id) { 'not-an-id' }

    it { expect(data[:errors]).to eq([{ message: I18n.t('graphql.mutations.demarche_brouillon.invalid_champ_id', id: 'not-an-id') }]) }
  end

  context 'with a token without the form editing scope' do
    let(:context) { super().merge(scopes: [APIToken::APPLICATION_READ, APIToken::APPLICATION_WRITE]) }

    it 'is refused' do
      expect(data[:errors]).to eq([{ message: I18n.t('graphql.mutations.demarche_brouillon.form_scope_required') }])
      expect(tdc('nom').libelle).to eq('nom')
    end
  end
end
