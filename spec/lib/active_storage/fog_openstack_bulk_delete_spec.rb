# frozen_string_literal: true

require 'rails_helper'

# Guards the monkeypatch in config/initializers/active_storage.rb that repairs
# fog-openstack's `delete_multiple_objects` (broken by the removal of URI.encode
# in Ruby 3.0).
describe Fog::OpenStack::Storage::Real, '#delete_multiple_objects' do
  subject(:real) { described_class.allocate }

  let(:captured) { {} }

  before do
    allow(real).to receive(:request) do |params, _|
      captured.merge!(params)
      Struct.new(:body).new('{"Number Deleted": 2, "Errors": []}')
    end
  end

  it 'does not raise (URI.encode is gone) and escapes each path, keeping the slash literal' do
    expect { real.delete_multiple_objects('bucket', ['key one', 'variants/abc/def']) }
      .not_to raise_error

    expect(captured[:body]).to eq("bucket/key%20one\nbucket/variants/abc/def")
    expect(captured[:query]).to eq('bulk-delete' => true)
    expect(captured[:method]).to eq('DELETE')
  end

  it 'decodes the JSON response body' do
    response = real.delete_multiple_objects('bucket', ['key'])

    expect(response.body).to eq('Number Deleted' => 2, 'Errors' => [])
  end

  # Canaries: the monkeypatch is only needed while BOTH remain true — Ruby lacks
  # URI.encode AND fog-openstack still calls it. When either stops holding, the
  # matching test fails: that is the signal to delete the patch and these tests.
  describe 'monkeypatch necessity' do
    it 'URI.encode is still undefined in this Ruby' do
      expect { URI.encode('x') }.to raise_error(NoMethodError)
    end

    it 'fog-openstack still ships the broken URI.encode call' do
      source_file = File.join(
        Gem.loaded_specs.fetch('fog-openstack').gem_dir,
        'lib/fog/openstack/storage/requests/delete_multiple_objects.rb'
      )

      expect(File.read(source_file)).to include('URI.encode')
    end
  end
end
