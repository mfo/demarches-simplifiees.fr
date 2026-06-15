# frozen_string_literal: true

describe NavBarProfileConcern do
  let(:instance) { ApplicationController.new }

  describe '#nav_bar_profile_from_referrer' do
    subject { instance.send(:nav_bar_profile_from_referrer) }

    before do
      allow(instance).to receive(:request).and_return(instance_double(ActionDispatch::Request, referer: referer))
    end

    context 'when the referer maps to a route declaring a nav_bar_profile' do
      let(:referer) { 'https://example.com/admin/procedures?nav_bar_profile=superadmin' }

      it { is_expected.to eq(:administrateur) }
    end

    context 'when the referer maps to a route without a nav_bar_profile' do
      let(:referer) { 'https://example.com/ping' }

      it { is_expected.to be_nil }
    end

    context 'when the referer does not match any route' do
      let(:referer) { 'https://example.com/does-not-exist' }

      it { is_expected.to be_nil }
    end

    context 'when the referer is nil' do
      let(:referer) { nil }

      it { is_expected.to be_nil }
    end
  end
end
