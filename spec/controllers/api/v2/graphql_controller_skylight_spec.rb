# frozen_string_literal: true

describe API::V2::GraphqlController do
  let_it_be(:admin) { administrateurs.default }
  let_it_be(:generated_token) { APIToken.generate(admin) }
  let_it_be(:procedure) { create(:procedure, :published, administrateurs: [admin]) }
  let(:token) { generated_token.second }
  let(:authorization_header) { ActionController::HttpAuthentication::Token.encode_credentials(token) }

  before do
    request.env['HTTP_AUTHORIZATION'] = authorization_header
  end

  describe 'skylight endpoint naming' do
    let(:trace) { instance_double(Skylight::Trace) }

    before do
      allow(Skylight).to receive(:instrumenter)
        .and_return(instance_double(Skylight::Instrumenter, current_trace: trace))
    end

    it 'names stored query traces after the operation' do
      expect(trace).to receive(:endpoint=).with('graphql:getDemarcheDescriptor')

      post :execute, params: { queryId: 'ds-query-v2', operationName: 'getDemarcheDescriptor', variables: { demarcheNumber: procedure.id } }, as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'buckets custom queries into a single endpoint' do
      expect(trace).to receive(:endpoint=).with('graphql:custom')

      post :execute, params: { query: "{ demarche(number: #{procedure.id}) { number } }" }, as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'still buckets custom queries that fail to parse' do
      expect(trace).to receive(:endpoint=).with('graphql:custom')

      post :execute, params: { query: '{ demarche(' }, as: :json
    end
  end
end
