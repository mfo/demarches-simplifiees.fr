# frozen_string_literal: true

RSpec.describe IdentityPrefillSource do
  let(:procedure) { create(:procedure, :for_individual, no_gender: false) }
  let(:dossier) { create(:dossier, :with_individual, procedure:, user:) }

  subject(:identity_source) { described_class.new(dossier:) }

  context "when the user has no identity provider" do
    let(:user) { create(:user) }

    it "resolves to no source and locks nothing" do
      expect(identity_source.resolved).to be_nil
      expect(identity_source).to be_none
      expect(identity_source.individual_locked_fields).to eq([])
      expect(identity_source.mandataire_locked?).to be(false)
    end
  end

  context "when the user is FranceConnected" do
    let(:user) { create(:user, :with_fci) }

    it "resolves to :france_connect and locks nom/prenom/gender" do
      expect(identity_source.resolved).to eq(:france_connect)
      expect(identity_source.individual_locked_fields).to contain_exactly(:nom, :prenom, :gender)
    end

    context "with an incomplete identity" do
      let(:user) { create(:user, france_connect_informations: [build(:france_connect_information, family_name: nil)]) }

      it { expect(identity_source.resolved).to be_nil }
    end
  end

  context "when the dossier is for_tiers" do
    let(:dossier) { create(:dossier, :for_tiers_without_notification, procedure:, user:) }

    context "FranceConnected" do
      let(:user) { create(:user, :with_fci) }

      it "locks the mandataire and nothing on the individual" do
        expect(identity_source.mandataire_locked?).to be(true)
        expect(identity_source.individual_locked_fields).to eq([])
      end
    end

    context "without an identity provider" do
      let(:user) { create(:user) }

      it { expect(identity_source.mandataire_locked?).to be(false) }
    end
  end
end
