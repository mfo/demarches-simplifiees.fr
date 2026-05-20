# frozen_string_literal: true

include ActiveJob::TestHelper

RSpec.describe APIEntreprise::Job, type: :job do
  describe '#perform' do
    let(:dossier) { create(:dossier, :with_entreprise) }

    context 'when error with an etablissement on a champ' do
      let(:procedure) { create(:procedure, types_de_champ_public:) }
      let(:types_de_champ_public) { [{ type: :siret }] }
      let(:dossier) { create(:dossier, procedure:) }

      it "re-raises so sidekiq can retry" do
        champ = dossier.champs.first
        champ.update!(value: '12345678901234')

        etablissement = create(:etablissement, champ:)

        expect { ErrorJob.perform_now(etablissement) }
          .to raise_error(StandardError, /API Entreprise error/)

        expect(champ.reload.value).not_to be_nil
      end
    end
  end

  describe '#with_adapter' do
    let(:job) { described_class.new }
    let(:adapter) { instance_double(APIEntreprise::Adapter) }

    context 'when adapter returns Success with data' do
      before { allow(adapter).to receive(:to_params).and_return(Dry::Monads::Success({ siret: '123' })) }

      it 'yields the params' do
        result = nil
        job.send(:with_adapter, adapter) { |params| result = params }
        expect(result).to eq({ siret: '123' })
      end
    end

    context 'when adapter returns Failure with forbidden (privilege not available)' do
      before { allow(adapter).to receive(:to_params).and_return(Dry::Monads::Failure(type: :forbidden, code: 403, retryable: false, raw_response: nil)) }

      it 'does not yield and logs' do
        yielded = false
        job.send(:with_adapter, adapter) { |_| yielded = true }
        expect(yielded).to be false
      end
    end

    context 'when adapter returns Failure with retryable error' do
      let(:response) do
        Typhoeus::Response.new(
          effective_url: 'http://host.com/path', code: '503', body: 'error',
          return_message: 'timeout', total_time: 10, connect_time: 20, headers: ''
        )
      end

      before do
        allow(adapter).to receive(:to_params)
          .and_return(Dry::Monads::Failure(type: :service_unavailable, code: 503, retryable: true, raw_response: response))
      end

      it 're-raises to trigger job retry' do
        expect { job.send(:with_adapter, adapter) { |_| } }.to raise_error(StandardError, /API Entreprise error:/)
      end
    end

    context 'when adapter returns Failure with retryable error but nil response' do
      before do
        allow(adapter).to receive(:to_params)
          .and_return(Dry::Monads::Failure(type: :token, code: 401, retryable: true, raw_response: nil))
      end

      it 'raises a StandardError with diagnostic message' do
        expect { job.send(:with_adapter, adapter) { |_| } }
          .to raise_error(StandardError, /API Entreprise error: type=token code=401/)
      end
    end

    context 'when adapter returns Failure with rate_limited and RateLimit-Reset header' do
      let(:reset_timestamp) { Time.current.to_i + 30 }
      let(:response) do
        Typhoeus::Response.new(
          effective_url: 'http://host.com/path', code: 429, body: '{"errors":[]}',
          return_message: 'too many requests', total_time: 1, connect_time: 0,
          headers: { 'RateLimit-Remaining' => '0', 'RateLimit-Reset' => reset_timestamp.to_s }
        )
      end

      before do
        allow(adapter).to receive(:to_params)
          .and_return(Dry::Monads::Failure(type: :rate_limited, code: 429, retryable: true, raw_response: response))
      end

      it 're-enqueues the job with wait based on RateLimit-Reset header' do
        expect(described_class).to receive(:set).with(wait: a_value_between(2.seconds, 30.seconds)).and_return(described_class)
        expect(described_class).to receive(:perform_later)
        job.send(:with_adapter, adapter) { |_| }
      end

      it 'does not raise' do
        allow(described_class).to receive(:set).and_return(described_class)
        allow(described_class).to receive(:perform_later)
        expect { job.send(:with_adapter, adapter) { |_| } }.not_to raise_error
      end
    end

    context 'when adapter returns Failure with rate_limited but no RateLimit-Reset header' do
      let(:response) do
        Typhoeus::Response.new(
          effective_url: 'http://host.com/path', code: 429, body: '{"errors":[]}',
          return_message: 'too many requests', total_time: 1, connect_time: 0, headers: ''
        )
      end

      before do
        allow(adapter).to receive(:to_params)
          .and_return(Dry::Monads::Failure(type: :rate_limited, code: 429, retryable: true, raw_response: response))
      end

      it 'falls back to raising for Sidekiq retry' do
        expect { job.send(:with_adapter, adapter) { |_| } }.to raise_error(StandardError, /rate_limited/)
      end
    end

    context 'when adapter returns Failure with non-retryable error' do
      before do
        allow(adapter).to receive(:to_params)
          .and_return(Dry::Monads::Failure(type: :unavailable_for_legal_reasons, code: 451, retryable: false, raw_response: nil))
      end

      it 'does not raise and returns nil' do
        result = job.send(:with_adapter, adapter) { |_| 'should not reach' }
        expect(result).to be_nil
      end

      it 'logs the non-retryable failure' do
        expect(Rails.logger).to receive(:info).with(/non-retryable.*type=unavailable_for_legal_reasons.*code=451/)
        job.send(:with_adapter, adapter) { |_| }
      end
    end
  end

  class ErrorJob < APIEntreprise::Job
    include Dry::Monads[:result]

    def perform(etablissement)
      @etablissement = etablissement
      adapter = Struct.new(:to_params).new(Failure(type: :service_unavailable, code: 503, retryable: true, raw_response: nil))
      with_adapter(adapter) { |_| }
    end
  end
end
