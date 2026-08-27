# frozen_string_literal: true

RSpec.describe Types::URL do
  describe '.coerce_input' do
    subject { described_class.coerce_input(input, {}) }

    context 'with a valid http(s) URL' do
      let(:input) { 'https://www.demarches-simplifiees.fr/commencer/test' }

      it { is_expected.to eq(Addressable::URI.parse(input)) }
    end

    context 'with a non-http scheme' do
      let(:input) { 'javascript:alert(1)' }

      it { expect { subject }.to raise_error(GraphQL::CoercionError) }
    end

    context 'with a relative URL' do
      let(:input) { '/commencer/test' }

      it { expect { subject }.to raise_error(GraphQL::CoercionError) }
    end

    context 'with an unparsable value' do
      let(:input) { 'http://example.com:port' }

      it { expect { subject }.to raise_error(GraphQL::CoercionError) }
    end
  end

  describe '.coerce_result' do
    it { expect(described_class.coerce_result(Addressable::URI.parse('https://example.com/a'), {})).to eq('https://example.com/a') }
  end
end
