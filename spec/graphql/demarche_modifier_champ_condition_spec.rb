# frozen_string_literal: true

RSpec.describe Mutations::DemarcheModifierChampCondition, type: :graphql do
  let(:admin) { administrateurs.default }
  let(:procedure) do
    create(:procedure, administrateurs: [admin], public_type_de_champs: [
      { type: :integer_number, libelle: 'age' },
      { type: :yes_no, libelle: 'etudiant' },
      { type: :text, libelle: 'boursier' },
    ])
  end
  let(:context) { { administrateur_id: admin.id, procedure_ids: admin.procedure_ids, scopes: [APIToken::FORM_WRITE], remote_ip: '192.168.1.23' } }
  let(:champ_id) { id('boursier') }
  let(:combinateur) { 'et' }
  let(:termes) { [{ champId: id('age'), operateur: 'less_than', valeur: '26' }] }
  let(:query) do
    <<~GRAPHQL
      mutation($input: DemarcheModifierChampConditionInput!) {
        demarcheModifierChampCondition(input: $input) {
          champDescriptor { id label }
          errors { message }
        }
      }
    GRAPHQL
  end

  subject { API::V2::Schema.execute(query, variables: { input: { demarche: { number: procedure.id }, champId: champ_id, combinateur:, termes: } }, context:) }

  let(:data) { subject['data']['demarcheModifierChampCondition'].deep_symbolize_keys }

  def tdc(libelle) = procedure.draft_revision.reload.type_de_champs.find { it.libelle == libelle }
  def id(libelle) = tdc(libelle).to_typed_id

  before { procedure }

  it 'sets the condition of the champ of the draft' do
    expect(data[:errors]).to be_nil
    expect(data[:champDescriptor]).to eq(id: id('boursier'), label: 'boursier')
    expect(tdc('boursier').condition).to eq(Logic::LessThan.new(Logic::ChampValue.new(tdc('age').stable_id), Logic::Constant.new(26)))
  end

  context 'with two terms and the ou combinator' do
    let(:combinateur) { 'ou' }
    let(:termes) { [{ champId: id('age'), operateur: 'less_than', valeur: '26' }, { champId: id('etudiant'), operateur: 'eq', valeur: 'true' }] }

    it 'combines them, the boolean read as a boolean' do
      expect(data[:errors]).to be_nil
      expect(tdc('boursier').condition).to be_a(Logic::Or)
      expect(tdc('boursier').condition.operands.last.right).to eq(Logic::Constant.new(true))
    end
  end

  context 'with a value a yes_no champ cannot be compared to' do
    let(:termes) { [{ champId: id('etudiant'), operateur: 'eq', valeur: 'Défavorable' }] }

    it 'is refused' do
      expect(data[:errors]).to be_present
      expect(tdc('boursier').condition).to be_nil
    end
  end

  context 'without term' do
    let(:termes) { [] }

    before { tdc('boursier').update!(condition: Logic::Eq.new(Logic::ChampValue.new(tdc('age').stable_id), Logic::Constant.new(18))) }

    it 'removes the condition' do
      expect(data[:errors]).to be_nil
      expect(tdc('boursier').condition).to be_nil
    end
  end

  context 'with a source placed after the champ' do
    let(:champ_id) { id('age') }
    let(:termes) { [{ champId: id('boursier'), operateur: 'eq', valeur: 'a' }] }

    it { expect(data[:errors].first[:message]).to include('« boursier »', 'avant') }
  end

  context 'with a champ of nowhere' do
    let(:champ_id) { GraphQL::Schema::UniqueWithinType.encode('Champ', 0) }

    it { expect(data[:errors].first[:message]).to include('n’existe pas dans le brouillon') }
  end

  context 'with a procedure of another administrateur' do
    let(:context) { super().merge(procedure_ids: []) }

    it { expect(data[:errors].first[:message]).to include('n’existe pas ou vous n’avez pas le droit') }
  end

  context 'with a token without the form editing scope' do
    let(:context) { super().merge(scopes: [APIToken::APPLICATION_READ, APIToken::APPLICATION_WRITE]) }

    it { expect(data[:errors]).to eq([{ message: I18n.t('graphql.mutations.demarche_brouillon.form_scope_required') }]) }
  end
end
