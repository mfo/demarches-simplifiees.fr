# frozen_string_literal: true

describe LockableConcern, type: :controller do
  controller(ApplicationController) do
    include LockableConcern

    def test_action
      lock_action(params.fetch(:lock_key)) do
        raise StandardError, 'boom' if params[:raise_in_action]
        render plain: 'Action completed'
      end
    end
  end

  before do
    routes.draw { get 'test_action/:lock_key' => 'anonymous#test_action' }
  end

  describe '#lock_action' do
    # randomize key to avoid collision on concurrent tests
    let(:lock_key) { "test_lock_#{SecureRandom.uuid}" }
    subject { get :test_action, params: { lock_key: } }

    context 'when there is no concurrent request' do
      it 'completes the action' do
        expect(subject).to have_http_status(:ok)
      end
    end

    context 'when there are concurrent requests' do
      it 'aborts the second request' do
        # Simulating the first request acquiring the lock
        Kredis.flag(lock_key).mark(expires_in: 3.seconds)

        # Making the second request
        expect(subject).to have_http_status(:locked)
      end
    end

    context 'when the lock expires' do
      it 'allows another request after expiration' do
        Kredis.flag(lock_key).mark(expires_in: 0.001.seconds)
        sleep 0.002

        expect(subject).to have_http_status(:ok)
      end
    end

    context 'when two overlapping requests reach the lock at the same time' do
      # Minimal host for the concern so each thread drives lock_action on its own
      # instance, without sharing controller request/response state across threads.
      let(:host_class) do
        Class.new do
          include LockableConcern

          attr_reader :locked_status

          def head(status)
            @locked_status = status
          end
        end
      end

      it 'runs the protected section only once' do
        executions = Concurrent::AtomicFixnum.new(0)
        start = Concurrent::CyclicBarrier.new(2)

        # Force the two threads to both finish reading the lock state before
        # either one writes it, reproducing the concurrent arrival deterministically.
        check_barrier = Concurrent::CyclicBarrier.new(2)
        shared_flag = Kredis.flag(lock_key)
        allow(Kredis).to receive(:flag).with(lock_key).and_return(shared_flag)
        allow(shared_flag).to receive(:marked?).and_wrap_original do |original|
          result = original.call
          check_barrier.wait(2)
          result
        end

        protected_section = proc do
          executions.increment
          # Hold the lock long enough that the other request genuinely overlaps.
          sleep 0.2
        end

        threads = Array.new(2) do
          Thread.new do
            host = host_class.new
            start.wait(2)
            host.lock_action(lock_key, &protected_section)
          end
        end
        threads.each(&:join)

        expect(executions.value).to eq(1)
      end
    end

    context 'when the protected section raises' do
      it 'releases the lock so a later request can run' do
        expect {
          get :test_action, params: { lock_key:, raise_in_action: true }
        }.to raise_error(StandardError, 'boom')

        expect(Kredis.flag(lock_key).marked?).to be(false)
      end
    end
  end
end
