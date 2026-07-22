# frozen_string_literal: true

RSpec.describe API::V2::Schema do
  describe 'query complexity budget' do
    def complexity_of(operation_name, variables)
      query = GraphQL::Query.new(
        described_class,
        API::V2::StoredQuery::QUERY_V2,
        variables: variables.transform_keys(&:to_s),
        operation_name:,
        context: { internal_use: false }
      )
      expect(query.static_errors).to be_empty
      GraphQL::Analysis::AST.analyze_query(query, [GraphQL::Analysis::AST::QueryComplexity]).first
    end

    it 'keeps the complexity limit enabled' do
      expect(described_class.max_complexity).to be_a(Integer).and(be > 0)
    end

    # Canary: the heaviest query our own client sends (getDemarche, a full page of
    # dossiers with every include on) must stay under budget. If this fails, the schema
    # grew past the budget — re-measure and raise max_complexity deliberately rather than
    # letting legitimate integrations start getting complexity errors in production.
    it 'admits the heaviest legitimate query with headroom' do
      complexity = complexity_of('getDemarche', {
        demarcheNumber: 1, includeDossiers: true, first: 100,
        includeChamps: true, includeAnotations: true, includeTraitements: true,
        includeInstructeurs: true, includeAvis: true, includeMessages: true,
        includeCorrections: true, includeGeometry: true, includeGroupeInstructeurs: true,
        includeService: true, includeRevision: true, includeRevisions: true,
        includePendingDeletedDossiers: true, includeDeletedDossiers: true,
        pendingDeletedFirst: 100, deletedFirst: 100,
      })

      # Sanity check that the query is genuinely heavy (guards a broken measurement).
      expect(complexity).to be > 20_000
      expect(complexity).to be < described_class.max_complexity
    end

    # The abuse vector: over-requesting the page size multiplies the per-node cost. The
    # query is rejected during analysis, before any resolver or DB access runs.
    it 'rejects an over-budget query before executing it' do
      result = described_class.execute(
        API::V2::StoredQuery::QUERY_V2,
        operation_name: 'getDemarche',
        variables: { 'demarcheNumber' => 1, 'includeDossiers' => true, 'first' => 250 },
        context: { internal_use: false }
      )

      expect(result['data']).to be_nil
      expect(result['errors'].map { _1['message'] }.join).to match(/complexity/i)
    end
  end
end

RSpec.describe API::V2::Schema::Timeout do
  describe '#filter_sensitive_query_string' do
    let(:timeout_instance) { described_class.new(max_seconds: 30) }

    before do
      Rails.application.config.filter_parameters += [:token] unless Rails.application.config.filter_parameters.include?(:token)
    end

    it 'filters sensitive patterns from the query string' do
      query_string = 'query getDemarche($demarcheNumber: Int!) { demarche(number: $demarcheNumber) { id, token } }'
      result = timeout_instance.send(:filter_sensitive_query_string, query_string.dup)

      expect(result).to eq('query getDemarche($demarcheNumber: Int!) { demarche(number: $demarcheNumber) { id, [FILTERED] } }')
    end
  end
end
