# frozen_string_literal: true

RSpec.describe ReferentielService, type: :service do
  describe '.test' do
    let(:type_de_champ) do
      build(:type_de_champ_referentiel, referentiel_url:, referentiel_test_data:, referentiel_adapter:)
    end
    let(:referentiel_adapter) { 'url' }
    let(:referentiel_url) { "https://api.fr/{id}/" }
    let(:referentiel_test_data) { "kthxbye" }

    context 'when referentiel_adapter is url', vcr: 'referentiel/test' do
      subject { described_class.new(type_de_champ:).test }

      it { is_expected.to eq(true) }
    end
  end
end
