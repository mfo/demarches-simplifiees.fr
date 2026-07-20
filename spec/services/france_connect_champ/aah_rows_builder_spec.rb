# frozen_string_literal: true

describe FranceConnectChamp::AAHRowsBuilder do
  describe '#build' do
    subject { described_class.new.build(data) }

    context 'when the user is a beneficiary' do
      let(:data) { { "est_beneficiaire" => true, "date_debut_droit" => "2024-01-15" } }

      it { is_expected.to include(["Bénéficiaire de l’AAH", "Oui"]) }
    end

    context 'when the user is not a beneficiary' do
      let(:data) { { "est_beneficiaire" => false } }

      it { is_expected.to eq([["Bénéficiaire de l’AAH", "Non"]]) }
    end
  end
end
