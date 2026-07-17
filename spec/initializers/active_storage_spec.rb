# frozen_string_literal: true

require "rails_helper"

RSpec.describe 'delete_multiple_objects bulk-delete patch' do
  # fog requires its original delete_multiple_objects (with the Ruby-3.0-removed
  # URI.encode) lazily, on the first client instantiation — after our initializer.
  # A prepended module stays ahead of Real in the ancestor chain, so it wins whatever
  # the load order; a plain class reopen would be clobbered (owner back to Real).
  it 'keeps the prepended patch ahead of the fog original' do
    expect(Fog::OpenStack::Storage::Real.instance_method(:delete_multiple_objects).owner)
      .to eq(OpenStackBulkDeletePatch)
  end
end
