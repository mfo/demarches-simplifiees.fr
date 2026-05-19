# frozen_string_literal: true

describe APIEntreprise::API do
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:siren) { '111111111' }

  def fixture_file(filename) = Rails.root.join('spec/fixtures/files/api_entreprise', filename).read

  describe '.entreprise' do
    subject { described_class.new(procedure_id).entreprise(siren) }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/)
        .to_return(body:, status:)
    end

    context 'when the service throws a bad gateaway exception' do
      let(:status) { 502 }
      let(:body) { fixture_file('entreprises_unavailable.json') }

      it 'returns a Failure with type :server_error' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :server_error, code: 502, retryable: true)
      end
    end

    context 'when the service reponds with 01000 code' do
      let(:status) { 502 }
      let(:body) { fixture_file('error_code_01000.json') }

      it 'returns a Failure with type :service_unavailable' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :service_unavailable, retryable: true)
      end
    end

    context 'when the service reponds with 01001 code' do
      let(:status) { 502 }
      let(:body) { fixture_file('error_code_01001.json') }

      it 'returns a Failure with type :service_unavailable' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :service_unavailable, retryable: true)
      end
    end

    context 'when the service reponds with 01002 code' do
      let(:status) { 504 }
      let(:body) { fixture_file('error_code_01002.json') }

      it 'returns a Failure with type :service_unavailable' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :service_unavailable, retryable: true)
      end
    end

    context 'when the service reponds with 02002 code' do
      let(:status) { 504 }
      let(:body) { fixture_file('error_code_02002.json') }

      it 'returns a Failure with type :service_unavailable' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :service_unavailable, retryable: true)
      end
    end

    context 'when the service reponds with 03002 code' do
      let(:status) { 504 }
      let(:body) { fixture_file('error_code_03002.json') }

      it 'returns a Failure with type :service_unavailable' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :service_unavailable, retryable: true)
      end
    end

    context 'when the service reponds with 03020 code' do
      let(:status) { 503 }
      let(:body) { fixture_file('error_code_03020.json') }

      it 'returns a Failure with type :service_unavailable' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :service_unavailable, retryable: true)
      end
    end

    context 'when siren does not exist' do
      let(:status) { 404 }
      let(:body) { fixture_file('entreprises_not_found.json') }

      it 'returns a Failure with type :not_found' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :not_found, code: 404, retryable: false)
      end
    end

    context 'when request has bad format' do
      let(:status) { 400 }
      let(:body) { fixture_file('entreprises_not_found.json') }

      it 'returns a Failure with type :server_error for undocumented code' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :server_error, code: 400, retryable: true)
      end
    end

    context 'when siren infos are private' do
      let(:status) { 403 }
      let(:body) { fixture_file('entreprises_private.json') }

      it 'returns a Failure with type :forbidden' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :forbidden, code: 403, retryable: false)
      end
    end

    context 'when rate limited (429)' do
      let(:status) { 429 }
      let(:body) { '{"errors":[{"code":"00429","title":"Trop de requêtes"}]}' }

      it 'returns a Failure with type :rate_limited' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :rate_limited, code: 429, retryable: true)
      end
    end

    context 'when unavailable for legal reasons (451)' do
      let(:status) { 451 }
      let(:body) { '{"errors":[{"code":"00451","title":"Indisponible pour raisons légales"}]}' }

      it 'returns a Failure with type :unavailable_for_legal_reasons' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :unavailable_for_legal_reasons, code: 451, retryable: false)
      end
    end

    context 'when siren exist' do
      let(:siren) { '418166096' }
      let(:status) { 200 }
      let(:body) { fixture_file('entreprises.json') }

      it 'returns Success with response body' do
        expect(subject).to be_success
        expect(subject.value!).to eq(JSON.parse(body, symbolize_names: true))
      end

      context 'with a service without siret' do
        let(:procedure) { create(:procedure, :with_service) }
        let(:dinum_siret) { "13002526500013" }
        it 'send default recipient' do
          ENV["API_ENTREPRISE_DEFAULT_SIRET"] = dinum_siret
          procedure.service.siret = nil
          procedure.service.save(validate: false)
          subject
          expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/).with(query: hash_including({ recipient: dinum_siret }))
        end
      end

      context 'with a service with siret' do
        context 'with a siren entreprise not equivalent to siret service' do
          let(:procedure) { create(:procedure, :with_service) }
          it 'send default recipient' do
            subject
            expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/).with(query: hash_including({ recipient: procedure.service.siret }))
          end
        end

        context 'with a siren entreprise equivalent to siret service' do
          let(:procedure) { create(:procedure, :with_service) }
          let(:siren) { procedure.service.siret[0..8] }
          let(:dinum_siret) { "13002526500013" }
          it 'send default recipient' do
            ENV["API_ENTREPRISE_DEFAULT_SIRET"] = dinum_siret
            subject
            expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/).with(query: hash_including({ recipient: dinum_siret }))
          end
        end
      end
    end

    context 'when the service reponds with 500 code' do
      let(:status) { 500 }
      let(:body) { fixture_file('error_500.html') }

      it 'returns a Failure with type :server_error' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :server_error, code: 500, retryable: true)
      end
    end
  end

  describe '.entreprise network errors' do
    subject { described_class.new(procedure_id).entreprise(siren) }

    context 'when the request times out' do
      before do
        # Stub at Client level since WebMock.to_timeout doesn't simulate Typhoeus timeout properly
        allow_any_instance_of(API::Client).to receive(:call).and_return(
          Dry::Monads::Failure(API::Client::Error[:timeout, 0, true, API::Client::HTTPError.new(
            Typhoeus::Response.new(effective_url: 'https://entreprise.api.gouv.fr/v3/path', code: 0, body: '', return_message: 'Timeout', total_time: 20, connect_time: 1, headers: '')
          )])
        )
      end

      it 'returns a Failure with type :timeout and retryable true' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :timeout, retryable: true)
      end
    end
  end

  describe '.etablissement' do
    subject { described_class.new(procedure_id).etablissement(siret) }
    before do
      stub_request(:get, "https://entreprise.api.gouv.fr/v3/insee/sirene/etablissements/#{siret}")
        .with(query: { "non_diffusables" => "true", "context" => APPLICATION_NAME, "object" => "procedure_id: #{procedure_id}", "recipient" => ENV.fetch("API_ENTREPRISE_DEFAULT_SIRET") })
        .to_return(status: status, body: body)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
    end

    context 'when siret does not exist' do
      let(:siret) { '11111111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'returns a Failure with type :not_found' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :not_found, code: 404)
      end
    end

    context 'when siret exists' do
      let(:siret) { '41816609600051' }
      let(:status) { 200 }
      let(:body) { fixture_file('etablissements.json') }

      it 'returns Success with body' do
        expect(subject).to be_success
        expect(subject.value!).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.exercices' do
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/dgfip\/etablissements\/#{siret}\/chiffres_affaires/)
        .to_return(status: status, body: body)
    end

    context 'when siret does not exist' do
      subject { described_class.new(procedure_id).exercices(siret) }

      let(:siret) { '11111111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'returns a Failure with type :not_found' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :not_found, code: 404)
      end
    end

    context 'when siret exists' do
      subject { described_class.new(procedure_id).exercices(siret) }

      let(:siret) { '41816609600051' }
      let(:status) { 200 }
      let(:body) { fixture_file('exercices.json') }

      it 'returns Success with body' do
        expect(subject).to be_success
        expect(subject.value!).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.rna' do
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/djepva\/api-association\/associations\/open_data\/#{siren}/)
        .to_return(status: status, body: body)
    end

    subject { described_class.new(procedure_id).rna(siren) }

    context 'when siren does not exist' do
      let(:siren) { '111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'returns a Failure with type :not_found' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :not_found, code: 404)
      end
    end

    context 'when siren exists' do
      let(:siren) { '418166096' }
      let(:status) { 200 }
      let(:body) { fixture_file('associations.json') }

      it 'returns Success with body' do
        expect(subject).to be_success
        expect(subject.value!).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.attestation_sociale' do
    let(:siren) { '418166096' }
    let(:status) { 200 }
    let(:body) { fixture_file('attestation_sociale.json') }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:can_fetch_attestation_sociale?).and_return(can_fetch)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/urssaf\/unites_legales\/#{siren}\/attestation_vigilance/)
        .to_return(body: body, status: status)
    end

    subject { described_class.new(procedure.id).attestation_sociale(siren) }

    context 'when token not authorized' do
      let(:can_fetch) { false }

      it 'returns a Failure with type :forbidden' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :forbidden, code: 403, retryable: false)
      end
    end

    context 'when token is authorized' do
      let(:can_fetch) { true }

      it 'returns Success with body' do
        expect(subject).to be_success
        expect(subject.value!).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.attestation_fiscale' do
    let(:siren) { '418166096' }
    let(:user_id) { 1 }
    let(:status) { 200 }
    let(:body) { fixture_file('attestation_fiscale.json') }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:can_fetch_attestation_fiscale?).and_return(can_fetch)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/dgfip\/unites_legales\/#{siren}\/attestation_fiscale/)
        .to_return(body:, status:)
    end

    subject { described_class.new(procedure.id).attestation_fiscale(siren, user_id) }

    context 'when token not authorized' do
      let(:can_fetch) { false }

      it 'returns a Failure with type :forbidden' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :forbidden, code: 403, retryable: false)
      end
    end

    context 'when token is authorized' do
      let(:can_fetch) { true }

      it 'returns Success with body' do
        expect(subject).to be_success
        expect(subject.value!).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.bilans_bdf' do
    let(:siren) { '418166096' }
    let(:status) { 200 }
    let(:body) { fixture_file('bilans_entreprise_bdf.json') }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:can_fetch_bilans_bdf?).and_return(can_fetch)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/banque_de_france\/unites_legales\/#{siren}\/bilans/)
        .to_return(body: body, status: status)
    end

    subject { described_class.new(procedure.id).bilans_bdf(siren) }

    context 'when token not authorized' do
      let(:can_fetch) { false }

      it 'returns a Failure with type :forbidden' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :forbidden, code: 403, retryable: false)
      end
    end

    context 'when token is authorized' do
      let(:can_fetch) { true }

      it 'returns Success with body' do
        expect(subject).to be_success
        expect(subject.value!).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.privileges' do
    let(:api) { described_class.new }
    let(:status) { 200 }
    let(:body) { fixture_file('privileges.json') }
    subject { api.privileges }

    before do
      api.token = APIEntrepriseToken.new(nil)

      allow(api.token).to receive(:jwt_token).and_return(double(blank?: blank))
      allow(api.token).to receive(:expired?).and_return(expired)

      stub_request(:get, "https://entreprise.api.gouv.fr/privileges")
        .to_return(body: body, status: status)
    end

    context 'with a blank token' do
      let(:blank) { true }
      let(:expired) { false }

      it 'returns a Failure with type :token_missing' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :token_missing, code: 401, retryable: false)
      end
    end

    context 'with a expired token' do
      let(:blank) { false }
      let(:expired) { true }

      it 'returns a Failure with type :token_expired' do
        expect(subject).to be_failure
        expect(subject.failure).to include(type: :token_expired, code: 401, retryable: false)
      end
    end

    context 'with a valid token' do
      let(:blank) { false }
      let(:expired) { false }

      it 'returns Success with body' do
        expect(subject).to be_success
        expect(subject.value!).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe 'with expired token' do
    let(:siren) { '111111111' }
    subject { described_class.new(procedure_id).entreprise(siren) }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(true)
    end

    it 'returns a Failure with type :token_expired and makes no call to api-entreprise' do
      expect(subject).to be_failure
      expect(subject.failure).to include(type: :token_expired, code: 401, retryable: false)
      expect(WebMock).not_to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}/)
    end
  end
end
