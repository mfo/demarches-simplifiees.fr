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

  it "logs the scope and size when skipping (without the URL)" do
    sentinel = "SENSITIVE_CHAMP_VALUE"
    huge = "/commencer/x?#{sentinel}=" + ("a" * max)

    expect(Rails.logger).to receive(:info)
      .with(a_string_including("user", huge.bytesize.to_s))
      .and_call_original

    subject.store_location_for(:user, huge)
  end

  it "never logs the URL content" do
    sentinel = "SENSITIVE_CHAMP_VALUE"
    huge = "/commencer/x?#{sentinel}=" + ("a" * max)

    logged = nil
    allow(Rails.logger).to receive(:info) { |msg| logged = msg }

    subject.store_location_for(:user, huge)

    expect(logged).to be_present
    expect(logged).not_to include(sentinel)
  end
end
