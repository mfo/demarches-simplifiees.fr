# frozen_string_literal: true

RSpec.describe 'closed by default visibility', type: :graphql do
  let(:admin) { administrateurs.default }
  let(:procedure) { procedures.individual }
  let(:variables) { { number: procedure.id } }

  def run(query, scopes:)
    API::V2::Schema.execute(query, variables:, context: { administrateur_id: admin.id, procedure_ids: admin.procedure_ids, scopes: })
  end

  def type_names(scopes:)
    run('{ __schema { types { name } } }', scopes:).dig('data', '__schema', 'types').map { it['name'] }
  end

  def field_names(type, scopes:)
    run("{ __type(name: \"#{type}\") { fields { name } } }", scopes:).dig('data', '__type', 'fields').map { it['name'] }
  end

  let(:form_scopes) { [] }
  let(:read_scopes) { [APIToken::APPLICATION_READ] }

  describe 'a token without the dossier read scope' do
    it 'reads the form of a procedure' do
      result = run('query($number: Int!) { demarche(number: $number) { title draftRevision { champDescriptors { __typename label } } service { nom } } }', scopes: form_scopes)

      expect(result['errors']).to be_nil
      expect(result.dig('data', 'demarche', 'title')).to eq(procedure.libelle)
    end

    it 'cannot ask for applications' do
      expect(run('query($number: Int!) { dossier(number: $number) { id } }', scopes: form_scopes)['errors'].first['message']).to include("doesn't exist on type 'Query'")
      expect(run('query($number: Int!) { demarche(number: $number) { dossiers { nodes { id } } } }', scopes: form_scopes)['errors']).to be_present
      expect(run('query($number: Int!) { demarche(number: $number) { deletedDossiers { nodes { id } } } }', scopes: form_scopes)['errors']).to be_present
    end

    it 'cannot ask for the reviewers or the administrators' do
      expect(run('query($number: Int!) { demarche(number: $number) { groupeInstructeurs { instructeurs { email } } } }', scopes: form_scopes)['errors']).to be_present
      expect(run('query($number: Int!) { demarche(number: $number) { administrateurs { email } } }', scopes: form_scopes)['errors']).to be_present
      expect(run('query($number: Int!) { groupeInstructeur(number: $number) { id } }', scopes: form_scopes)['errors']).to be_present
    end

    it 'sees no mutation' do
      expect(type_names(scopes: form_scopes)).not_to include('Mutation')
    end

    it 'only sees the form types' do
      names = type_names(scopes: form_scopes)

      expect(names).to include('Demarche', 'Revision', 'TextChampDescriptor', 'Service')
      expect(names).not_to include('Dossier', 'Message', 'Avis', 'Profile', 'GroupeInstructeur', 'PersonnePhysique', 'TextChamp', 'DeletedDossier', 'Label')
      expect(field_names('Demarche', scopes: form_scopes)).not_to include('dossiers', 'administrateurs', 'groupeInstructeurs', 'labels', 'chorusConfiguration')
    end
  end

  describe 'a token with the dossier read scope' do
    it 'sees the whole schema' do
      expect(type_names(scopes: read_scopes)).to include('Dossier', 'Message', 'Profile', 'Mutation')
      expect(field_names('Demarche', scopes: read_scopes)).to include('dossiers', 'administrateurs', 'groupeInstructeurs')
    end
  end

  describe 'every field of a type opened field by field' do
    it 'is listed on purpose' do
      expect(Types::DemarcheType.form_field?(:dossiers)).to be(false)
      expect(Types::DemarcheType.form_field?(:title)).to be(true)
    end
  end

  describe 'the write scope' do
    it 'only comes from an explicit write scope, or from the legacy write_access' do
      write = API::V2::Schema.execute('{ __typename }', context: { scopes: APIToken::SCOPES }).context
      read = API::V2::Schema.execute('{ __typename }', context: { scopes: read_scopes }).context
      legacy = API::V2::Schema.execute('{ __typename }', context: { write_access: true }).context

      expect([write.write_access?, read.write_access?, legacy.write_access?]).to eq([true, false, true])
    end
  end
end
