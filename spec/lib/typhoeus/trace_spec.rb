# frozen_string_literal: true

RSpec.describe Typhoeus::Trace do
  before { allow(Rails.logger).to receive(:info) }

  def response_for(url, method: nil, **options)
    Typhoeus::Response.new(**options).tap do |response|
      response.request = Typhoeus::Request.new(url, **{ method: }.compact)
    end
  end

  describe '.log' do
    it 'traces the verb, the endpoint and the status' do
      described_class.log(response_for("https://ami.example.org/api/v2/event", method: :put, code: 201, total_time: 0.1181))

      expect(Rails.logger).to have_received(:info).with("[HTTP] PUT ami.example.org/api/v2/event → 201 (118ms)")
    end

    it 'assumes GET when the request carries no method' do
      described_class.log(response_for("https://geo.api.gouv.fr/communes", code: 200, total_time: 0.041))

      expect(Rails.logger).to have_received(:info).with("[HTTP] GET geo.api.gouv.fr/communes → 200 (41ms)")
    end

    it 'never logs the query string, which carries signatures and civil status' do
      described_class.log(response_for("https://storage.example.org/blob/xyz?temp_url_sig=s3cr3t&temp_url_expires=1", code: 200, total_time: 0.02))

      expect(Rails.logger).to have_received(:info).with("[HTTP] GET storage.example.org/blob/xyz → 200 (20ms)")
    end

    it 'marks cache hits instead of a duration' do
      response = response_for("https://geo.api.gouv.fr/communes", code: 200, total_time: 0.0)
      response.cached = true

      described_class.log(response)

      expect(Rails.logger).to have_received(:info).with("[HTTP] GET geo.api.gouv.fr/communes → 200 (cache)")
    end

    it 'reports the curl return code when no response came back' do
      described_class.log(response_for("https://hooks.example.org/webhook", method: :post, code: 0, return_code: :couldnt_connect))

      expect(Rails.logger).to have_received(:info).with("[HTTP] POST hooks.example.org/webhook → 0 (couldnt_connect)")
    end

    it 'returns the response, so the callback chain is left untouched' do
      response = response_for("https://example.org/ping", code: 200, total_time: 0.0)

      expect(described_class.log(response)).to eq(response)
    end

    it 'never breaks the call it observes' do
      allow(Rails.logger).to receive(:debug)
      response = Typhoeus::Response.new(code: 200)

      expect { described_class.log(response) }.not_to raise_error
      expect(response).to eq(described_class.log(response))
      expect(Rails.logger).not_to have_received(:info)
    end
  end

  describe 'wired as a global Typhoeus callback' do
    around do |example|
      hook = -> (response) { described_class.log(response) } # mirrors config/initializers/typhoeus.rb
      Typhoeus.on_complete << hook
      example.run
    ensure
      # never `Typhoeus.on_complete.clear`: it would drop WebMock's own callback
      Typhoeus.on_complete.delete(hook)
    end

    it 'traces a request whatever the call site, without altering the handled response' do
      stub_request(:get, "https://example.org/ping").to_return(status: 200, body: "{}")

      response = Typhoeus.get("https://example.org/ping")

      expect(Rails.logger).to have_received(:info).with("[HTTP] GET example.org/ping → 200 (0ms)")
      expect(response.handled_response).to eq(response)
    end
  end
end
