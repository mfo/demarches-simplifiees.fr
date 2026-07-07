# frozen_string_literal: true

RSpec.describe Typhoeus::EasyFactory do
  describe 'proxy tracing headers' do
    let(:request) { Typhoeus::Request.new('http://example.com') }

    subject(:easy) { described_class.new(request).get }

    it 'sets X-Request-Id and X-Job-Id from Current on the easy handle' do
      Current.set(request_id: 'req-123', job_id: 'job-456') do
        expect(easy.proxy_headers).to eq({ 'X-Request-Id' => 'req-123', 'X-Job-Id' => 'job-456' })
      end
    end

    it 'omits headers without value' do
      Current.set(request_id: 'req-123') do
        expect(easy.proxy_headers).to eq({ 'X-Request-Id' => 'req-123' })
      end
    end

    it 'sets no proxy headers outside of a request or job context' do
      expect(easy.proxy_headers).to be_nil
    end

    it 'does not alter the request options, keeping the cache key stable' do
      cache_key = Typhoeus::Request.new('http://example.com').cache_key

      Current.set(request_id: 'req-123') do
        easy
        expect(request.cache_key).to eq(cache_key)
      end
    end
  end
end
