# frozen_string_literal: true

RSpec.describe IdentityPrefillSource do
  let(:procedure) { create(:procedure, :for_individual, no_gender: false) }
  let(:dossier) { create(:dossier, :with_individual, procedure:, user:) }
  let(:source) { :france_connect }

  subject(:identity_source) { described_class.new(dossier:, source:) }

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

  context "when the session is ProConnected" do
    let(:user) { create(:user, :with_pci) }
    let(:source) { :pro_connect }

    it "resolves to :pro_connect and locks nom/prenom but not gender" do
      expect(identity_source.resolved).to eq(:pro_connect)
      expect(identity_source.individual_locked_fields).to contain_exactly(:nom, :prenom)
    end

    context "when ProConnect did not provide a usual name" do
      let(:user) { create(:user, pro_connect_informations: [build(:pro_connect_information, usual_name: nil)]) }

      it { expect(identity_source.resolved).to be_nil }
    end

    context "but the request does not prefer ProConnect" do
      let(:source) { :france_connect }

      it { expect(identity_source.resolved).to be_nil }
    end
  end

  context "when the user has both identities" do
    let(:user) { create(:user, :with_fci, :with_pci) }

    context "and the session is ProConnected" do
      let(:source) { :pro_connect }

      it "the current session wins" do
        expect(identity_source.resolved).to eq(:pro_connect)
        expect(identity_source.individual_locked_fields).to contain_exactly(:nom, :prenom)
      end
    end

    context "and the session is not ProConnected" do
      it "falls back to FranceConnect" do
        expect(identity_source.resolved).to eq(:france_connect)
        expect(identity_source.individual_locked_fields).to contain_exactly(:nom, :prenom, :gender)
      end
    end

    context "with the ProConnect session but an incomplete ProConnect identity" do
      let(:user) { create(:user, :with_fci, pro_connect_informations: [build(:pro_connect_information, usual_name: nil)]) }
      let(:source) { :pro_connect }

      it "falls back to FranceConnect" do
        expect(identity_source.resolved).to eq(:france_connect)
      end
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

    context "ProConnected" do
      let(:user) { create(:user, :with_pci) }
      let(:source) { :pro_connect }

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

  describe "#pro_connect_siret" do
    subject { identity_source.pro_connect_siret }

    context "when the session is ProConnected" do
      let(:user) { create(:user, :with_pci) }
      let(:source) { :pro_connect }

      it { is_expected.to eq('12345678901234') }

      context "and ProConnect did not provide an identity" do
        let(:user) { create(:user, pro_connect_informations: [build(:pro_connect_information, given_name: nil, usual_name: nil)]) }

        it "is still available: the siret does not depend on the identity being complete" do
          expect(identity_source.resolved).to be_nil
          expect(subject).to eq('12345678901234')
        end
      end

      context "and ProConnect did not provide a siret" do
        let(:user) { create(:user, pro_connect_informations: [build(:pro_connect_information, siret: nil)]) }

        it { is_expected.to be_nil }
      end

      context "but the user has no ProConnect information" do
        let(:user) { create(:user) }

        it { is_expected.to be_nil }
      end
    end

    context "when the session is not ProConnected" do
      let(:user) { create(:user, :with_pci) }

      it { is_expected.to be_nil }
    end
  end
end
