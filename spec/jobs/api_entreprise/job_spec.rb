# frozen_string_literal: true

RSpec.describe APIEntreprise::Job, type: :job do
  include ActiveJob::TestHelper
  before do
    [5, 50, 100, 250].each do |pool|
      Kredis.redis.del(APIEntreprise::RateLimiter.remaining_key(pool), APIEntreprise::RateLimiter.reset_key(pool))
    end
  end

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

  describe 'before_perform rate limit check' do
    let(:pool) { APIEntreprise::API::DEFAULT_POOL }

    context 'when not throttled' do
      before { allow(APIEntreprise::RateLimiter).to receive(:throttled?).with(pool).and_return(false) }

      it 'runs the job normally' do
        dossier = create(:dossier, :with_entreprise)
        etablissement = dossier.etablissement

        expect { ErrorJob.perform_now(etablissement) }.to raise_error(StandardError, /API Entreprise error/)
      end
    end

    context 'when throttled' do
      before do
        allow(APIEntreprise::RateLimiter).to receive(:throttled?).with(pool).and_return(true)
        allow(APIEntreprise::RateLimiter).to receive(:wait_duration).with(pool).and_return(15)
      end

      it 're-enqueues the job with delay and aborts' do
        dossier = create(:dossier, :with_entreprise)
        etablissement = dossier.etablissement

        expect(ErrorJob).to receive(:set).with(wait: a_value_between(15.seconds, 30.seconds)).and_return(ErrorJob)
        expect(ErrorJob).to receive(:perform_later).with(etablissement)

        ErrorJob.perform_now(etablissement)
      end

      it 'does not execute the job body' do
        dossier = create(:dossier, :with_entreprise)
        etablissement = dossier.etablissement

        allow(ErrorJob).to receive(:set).and_return(ErrorJob)
        allow(ErrorJob).to receive(:perform_later)

        # If the job body ran, it would raise — no raise means abort worked
        expect { ErrorJob.perform_now(etablissement) }.not_to raise_error
      end
    end
  end

  describe '#api_pool' do
    it 'returns the correct pool for each job class' do
      expect(APIEntreprise::EtablissementJob.new.api_pool).to eq(250)
      expect(APIEntreprise::EntrepriseJob.new.api_pool).to eq(250)
      expect(APIEntreprise::ExtraitKbisJob.new.api_pool).to eq(250)
      expect(APIEntreprise::TvaJob.new.api_pool).to eq(250)
      expect(APIEntreprise::ExercicesJob.new.api_pool).to eq(250)
      expect(APIEntreprise::AssociationJob.new.api_pool).to eq(250)
      expect(APIEntreprise::BilansBdfJob.new.api_pool).to eq(250)
      expect(APIEntreprise::ServiceJob.new.api_pool).to eq(250)
      expect(APIEntreprise::EffectifsJob.new.api_pool).to eq(50)
      expect(APIEntreprise::EffectifsAnnuelsJob.new.api_pool).to eq(50)
      expect(APIEntreprise::AttestationSocialeJob.new.api_pool).to eq(100)
      expect(APIEntreprise::AttestationFiscaleJob.new.api_pool).to eq(5)
    end

    it 'defaults to 250 for unknown job classes' do
      expect(ErrorJob.new.api_pool).to eq(250)
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

    context 'when adapter returns Failure with rate_limited' do
      before do
        allow(adapter).to receive(:to_params)
          .and_return(Dry::Monads::Failure(type: :rate_limited, code: 429, retryable: true, raw_response: nil))
      end

      it 're-enqueues the job with wait from RateLimiter.wait_duration' do
        allow(APIEntreprise::RateLimiter).to receive(:wait_duration).and_return(20)
        expect(described_class).to receive(:set).with(wait: 20.seconds).and_return(described_class)
        expect(described_class).to receive(:perform_later)
        job.send(:with_adapter, adapter) { |_| }
      end

      it 'does not raise' do
        allow(described_class).to receive(:set).and_return(described_class)
        allow(described_class).to receive(:perform_later)
        expect { job.send(:with_adapter, adapter) { |_| } }.not_to raise_error
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

  describe 'sidekiq retry configuration' do
    subject(:options) { described_class.get_sidekiq_options }

    it 'defers Sentry reporting until the 8th attempt while keeping native retry' do
      expect(options["attempt_threshold"]).to eq(8)
      expect(options["retry"]).to eq(ActiveJob::RetryOnStandardError::MAX_ATTEMPTS_JOBS)
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
