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
    Array(run("{ __type(name: \"#{type}\") { fields { name } } }", scopes:).dig('data', '__type', 'fields')).map { it['name'] }
  end

  let(:form_scopes) { [APIToken::FORM_WRITE] }
  let(:read_scopes) { [APIToken::APPLICATION_READ] }

  describe 'a token without the application read scope' do
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

    it 'sees only the form editing mutations' do
      expect(type_names(scopes: form_scopes)).to include('Mutation')
      expect(field_names('Mutation', scopes: form_scopes)).to contain_exactly('demarcheSupprimerChamp', 'demarcheDeplacerChamp', 'demarcheAjouterChamp')
    end

    it 'only sees the form types' do
      names = type_names(scopes: form_scopes)

      expect(names).to include('Demarche', 'Revision', 'TextChampDescriptor', 'Service')
      expect(names).not_to include('Dossier', 'Message', 'Avis', 'Profile', 'GroupeInstructeur', 'PersonnePhysique', 'TextChamp', 'DeletedDossier', 'Label')
      expect(field_names('Demarche', scopes: form_scopes)).not_to include('dossiers', 'administrateurs', 'groupeInstructeurs', 'labels', 'chorusConfiguration')
    end
  end

  describe 'a token with the application read scope' do
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
      write = API::V2::Schema.execute('{ __typename }', context: { scopes: APIToken::APPLICATION_SCOPES }).context
      read = API::V2::Schema.execute('{ __typename }', context: { scopes: read_scopes }).context
      legacy = API::V2::Schema.execute('{ __typename }', context: { write_access: true }).context

      expect([write.write_access?, read.write_access?, legacy.write_access?]).to eq([true, false, true])
    end
  end

  describe 'the descriptor of a procedure' do
    let(:query) { 'query($number: Int!) { demarcheDescriptor(demarche: { number: $number }) { title dossiersCount } }' }

    it 'hides the dossiers count from a form token, and gives it to a read token' do
      expect(run(query, scopes: form_scopes)['errors'].first['message']).to include("dossiersCount")
      expect(run(query, scopes: read_scopes).dig('data', 'demarcheDescriptor', 'dossiersCount')).to be_a(Integer)
    end
  end

  describe 'the champ descriptors of a form' do
    it 'lists the options of the geographic descriptors' do
      query = '{ __type(name: "PaysChampDescriptor") { fields { name } } }'
      expect(run(query, scopes: form_scopes).dig('data', '__type', 'fields').map { it['name'] }).to include('options')
    end
  end

  describe 'the types opened to a form token' do
    it 'only differ from the full schema on Query, Mutation, Demarche and DemarcheDescriptor' do
      gaps = type_names(scopes: form_scopes).filter do |type|
        (field_names(type, scopes: read_scopes) - field_names(type, scopes: form_scopes)).any?
      end

      expect(gaps - ['Query', 'Mutation', 'Demarche', 'DemarcheDescriptor']).to eq([])
    end
  end

  describe 'a token with the form scope only' do
    it 'carries the scope but cannot write applications, nor publish' do
      context = API::V2::Schema.execute('{ __typename }', context: { scopes: form_scopes }).context

      expect(context.form_write?).to be true
      expect(context.write_access?).to be false
      expect(context.application_read?).to be false
      expect(type_names(scopes: form_scopes)).not_to include('DemarchePublierInput')
    end

    it 'does not make an application token a form editor' do
      context = API::V2::Schema.execute('{ __typename }', context: { scopes: APIToken::APPLICATION_SCOPES }).context

      expect(context.form_write?).to be false
    end
  end

  describe 'a write-only token' do
    it 'also reads' do
      names = type_names(scopes: [APIToken::APPLICATION_WRITE])

      expect(names).to include('Mutation', 'Dossier')
    end
  end

  describe 'without a query' do
    it 'sees the whole schema' do
      expect { API::V2::Schema.get_type('Dossier') }.not_to raise_error
      expect(API::V2::Schema.get_type('Dossier')).to be_present
    end
  end

  describe 'a stored query' do
    def stored(query_id, scopes:)
      API::V2::StoredQuery.execute(query_id, variables: { demarcheNumber: procedure.id }, operation_name: 'getDemarche',
        context: { administrateur_id: admin.id, procedure_ids: admin.procedure_ids, scopes: })
    end

    it 'is refused to a form token with a clear error' do
      expect { stored('ds-query-v2', scopes: form_scopes) }.to raise_error(GraphQL::ExecutionError, /application_read/)
    end

    it 'still lets a form token introspect' do
      result = API::V2::StoredQuery.execute('introspection', variables: {}, operation_name: nil, context: { scopes: form_scopes })

      expect(result['errors']).to be_nil
    end

    it 'runs for a read token' do
      expect(stored('ds-query-v2', scopes: read_scopes)['errors']).to be_nil
    end
  end
end
