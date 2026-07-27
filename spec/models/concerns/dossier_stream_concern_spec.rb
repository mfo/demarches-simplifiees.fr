# frozen_string_literal: true

RSpec.describe DossierStreamConcern do
  describe "#can_update_as_instructeur?" do
    let(:procedure) { create(:procedure, :published, instructeurs: [instructeur], instructeurs_can_edit_dossiers:) }
    let(:instructeur) { create(:instructeur) }
    let(:dossier) { create(:dossier, :en_construction, procedure:) }
    let(:instructeurs_can_edit_dossiers) { true }

    subject { dossier.can_update_as_instructeur?(instructeur.user) }

    context "when the procedure allows it and the user is an instructeur of the groupe" do
      it { is_expected.to be_truthy }
    end

    context "when the procedure does not allow instructeur edition" do
      let(:instructeurs_can_edit_dossiers) { false }

      it { is_expected.to be_falsey }
    end

    context "when the dossier is not en_construction" do
      let(:dossier) { create(:dossier, :en_instruction, procedure:) }

      it { is_expected.to be_falsey }
    end

    context "when the user is not an instructeur of the groupe" do
      subject { dossier.can_update_as_instructeur?(create(:instructeur).user) }

      it { is_expected.to be_falsey }
    end

    context "when the instructeur owns the dossier" do
      let(:dossier) { create(:dossier, :en_construction, procedure:, user: instructeur.user) }

      it { is_expected.to be_falsey }
    end
  end

  describe "#can_update_as_user?" do
    let(:procedure) { create(:procedure, :published) }
    let(:dossier) { create(:dossier, :en_construction, procedure:) }

    subject { dossier.can_update_as_user?(user) }

    context "when the user owns the dossier" do
      let(:user) { dossier.user }

      it { is_expected.to be_truthy }
    end

    context "when the user is a stranger" do
      let(:user) { create(:user) }

      it { is_expected.to be_falsey }
    end

    context "when the dossier is not en_construction" do
      let(:dossier) { create(:dossier, :en_instruction, procedure:) }
      let(:user) { dossier.user }

      it { is_expected.to be_falsey }
    end
  end

  describe "#with_stream" do
    let(:dossier) { create(:dossier, :en_construction) }

    it "defaults to the main stream" do
      expect(dossier.stream).to eq(Dossier::MAIN_STREAM)
      expect(dossier).to be_main_stream
    end

    it "restores the previous stream after a block" do
      dossier.with_instructeur_buffer_stream do
        expect(dossier.stream).to eq(Dossier::INSTRUCTEUR_BUFFER_STREAM)
      end

      expect(dossier.stream).to eq(Dossier::MAIN_STREAM)
    end

    it "pins the stream on the instance when called without a block" do
      expect(dossier.with_update_stream(dossier.user)).to eq(dossier)
      expect(dossier.stream).to eq(Dossier::USER_BUFFER_STREAM)
    end

    it "nests blocks" do
      dossier.with_update_stream(dossier.user) do
        dossier.with_main_stream do
          expect(dossier.stream).to eq(Dossier::MAIN_STREAM)
        end

        expect(dossier.stream).to eq(Dossier::USER_BUFFER_STREAM)
      end

      expect(dossier.stream).to eq(Dossier::MAIN_STREAM)
    end

    it "returns the block result" do
      expect(dossier.with_main_stream { :result }).to eq(:result)
    end
  end
end
