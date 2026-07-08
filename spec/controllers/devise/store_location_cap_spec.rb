# frozen_string_literal: true

RSpec.describe "Devise store_location_for byte cap", type: :controller do
  controller(ActionController::Base) do
    include Devise::Controllers::StoreLocation
  end

  let(:max) { Devise::Controllers::StoreLocationCap::MAX_STORED_LOCATION_BYTES }

  it "stores a normal-size location" do
    subject.store_location_for(:user, "/dossiers?statut=en-cours")

    expect(subject.session["user_return_to"]).to eq("/dossiers?statut=en-cours")
  end

  it "does not store a location larger than the cap" do
    huge = "/commencer/ma-demarche?" + ("champ_Z=valeur&" * 200)
    expect(huge.bytesize).to be > max

    subject.store_location_for(:user, huge)

    expect(subject.session["user_return_to"]).to be_nil
  end
end
