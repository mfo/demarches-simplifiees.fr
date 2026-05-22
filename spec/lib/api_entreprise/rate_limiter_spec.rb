# frozen_string_literal: true

require 'rails_helper'

describe APIEntreprise::RateLimiter do
  before do
    Kredis.redis.del(described_class::REMAINING_KEY, described_class::RESET_KEY)
  end

  describe '.throttled?' do
    context 'when Redis has no state' do
      it 'returns false' do
        expect(described_class.throttled?).to be false
      end
    end

    context 'when remaining > 0' do
      before { Kredis.redis.set(described_class::REMAINING_KEY, 10, ex: 60) }

      it 'returns false' do
        expect(described_class.throttled?).to be false
      end
    end

    context 'when remaining = 0' do
      before { Kredis.redis.set(described_class::REMAINING_KEY, 0, ex: 60) }

      it 'returns true' do
        expect(described_class.throttled?).to be true
      end
    end

    context 'when remaining < 0 (over-decremented)' do
      before { Kredis.redis.set(described_class::REMAINING_KEY, -3, ex: 60) }

      it 'returns true' do
        expect(described_class.throttled?).to be true
      end
    end
  end

  describe '.consume!' do
    context 'when Redis has no state (not yet calibrated)' do
      it 'does nothing' do
        expect { described_class.consume! }.not_to raise_error
        expect(Kredis.redis.get(described_class::REMAINING_KEY)).to be_nil
      end
    end

    context 'when remaining is set' do
      before { Kredis.redis.set(described_class::REMAINING_KEY, 5, ex: 60) }

      it 'atomically decrements' do
        described_class.consume!
        expect(Kredis.redis.get(described_class::REMAINING_KEY).to_i).to eq(4)
      end

      it 'is safe under concurrent calls' do
        3.times { described_class.consume! }
        expect(Kredis.redis.get(described_class::REMAINING_KEY).to_i).to eq(2)
      end
    end
  end

  describe '.calibrate!' do
    let(:reset_timestamp) { Time.current.to_i + 30 }

    context 'with a response containing RateLimit headers' do
      let(:response) do
        Typhoeus::Response.new(
          effective_url: 'http://host.com/path', code: 200, body: '{}',
          return_message: 'ok', total_time: 1, connect_time: 0,
          headers: { 'RateLimit-Remaining' => '42', 'RateLimit-Reset' => reset_timestamp.to_s }
        )
      end

      it 'sets remaining in Redis but not reset (remaining > 0)' do
        described_class.calibrate!(response)

        expect(Kredis.redis.get(described_class::REMAINING_KEY).to_i).to eq(42)
        expect(Kredis.redis.get(described_class::RESET_KEY)).to be_nil
      end

      it 'sets TTL based on reset timestamp' do
        described_class.calibrate!(response)

        ttl = Kredis.redis.ttl(described_class::REMAINING_KEY)
        expect(ttl).to be_between(1, 30)
      end
    end

    context 'with a response without RateLimit headers' do
      let(:response) do
        Typhoeus::Response.new(
          effective_url: 'http://host.com/path', code: 200, body: '{}',
          return_message: 'ok', total_time: 1, connect_time: 0, headers: ''
        )
      end

      it 'does not write to Redis' do
        described_class.calibrate!(response)
        expect(Kredis.redis.get(described_class::REMAINING_KEY)).to be_nil
      end
    end

    context 'with nil response' do
      it 'does not write to Redis' do
        described_class.calibrate!(nil)
        expect(Kredis.redis.get(described_class::REMAINING_KEY)).to be_nil
      end
    end
  end

  describe '.wait_duration' do
    context 'when reset key is not set' do
      it 'returns 2 seconds default' do
        expect(described_class.wait_duration).to eq(2)
      end
    end

    context 'when reset is in the future' do
      before do
        Kredis.redis.set(described_class::RESET_KEY, Time.current.to_i + 25, ex: 60)
      end

      it 'returns seconds until reset' do
        expect(described_class.wait_duration).to be_between(23, 25)
      end
    end

    context 'when reset is in the past' do
      before do
        Kredis.redis.set(described_class::RESET_KEY, Time.current.to_i - 5, ex: 60)
      end

      it 'returns minimum of 2 seconds' do
        expect(described_class.wait_duration).to eq(2)
      end
    end
  end
end
