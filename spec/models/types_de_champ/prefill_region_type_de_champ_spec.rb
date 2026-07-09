# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillRegionTypeDeChamp, type: :model do
  let(:procedure) { create(:procedure) }
  let(:type_de_champ) { create(:type_de_champ_regions, procedure: procedure) }

  describe 'ancestors' do
    subject { described_class.build(type_de_champ, procedure.active_revision) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#possible_values' do
    let(:expected_values) { "Un <a href=\"https://fr.wikipedia.org/wiki/R%C3%A9gion_fran%C3%A7aise\" target=\"_blank\" rel=\"noopener noreferrer\">code INSEE de région</a><br><a title=\"Toutes les valeurs possibles — Nouvel onglet\" target=\"_blank\" rel=\"noopener noreferrer\" href=\"/procedures/#{procedure.path}/prefill_type_de_champs/#{type_de_champ.id}\">Voir toutes les valeurs possibles</a>" }
    subject(:possible_values) { described_class.new(type_de_champ, procedure.active_revision).possible_values }

    before { type_de_champ.reload }

    it {
      expect(possible_values).to eq(expected_values)
    }
  end

  describe '#to_assignable_attributes' do
    let(:champ) { Champs::RegionChamp.new }
    subject(:to_assignable_attributes) { described_class.build(type_de_champ, procedure.active_revision).to_assignable_attributes(champ, value) }

    context 'when the value is a region code' do
      let(:value) { '53' }

      it { is_expected.to eq({ value: '53' }) }
    end

    context 'when the value is a region name' do
      let(:value) { 'Bretagne' }

      it { is_expected.to eq({ value: 'Bretagne' }) }
    end

    context 'when the value is an unknown region code' do
      let(:value) { '00' }

      it { is_expected.to be_nil }
    end

    context 'when the value is not a region' do
      let(:value) { 'value' }

      it { is_expected.to be_nil }
    end

    context 'when the value is not a String' do
      let(:value) { ['53'] }

      it { is_expected.to be_nil }
    end
  end
end
