# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillPaysTypeDeChamp, type: :model do
  let(:procedure) { create(:procedure) }
  let(:type_de_champ) { build(:type_de_champ_pays, procedure: procedure) }

  describe 'ancestors' do
    subject { described_class.build(type_de_champ, procedure.active_revision) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#possible_values' do
    let(:expected_values) { "Un <a href=\"https://en.wikipedia.org/wiki/ISO_3166-2\" target=\"_blank\" rel=\"noopener noreferrer\">code pays ISO 3166-2</a><br><a title=\"Toutes les valeurs possibles — Nouvel onglet\" target=\"_blank\" rel=\"noopener noreferrer\" href=\"/procedures/#{procedure.path}/prefill_type_de_champs/#{type_de_champ.id}\">Voir toutes les valeurs possibles</a>" }
    subject(:possible_values) { described_class.new(type_de_champ, procedure.active_revision).possible_values }

    before { type_de_champ.reload }

    it {
      expect(possible_values).to match(expected_values)
    }
  end

  describe '#to_assignable_attributes' do
    let(:champ) { Champs::PaysChamp.new }
    subject(:to_assignable_attributes) { described_class.build(type_de_champ, procedure.active_revision).to_assignable_attributes(champ, value) }

    context 'when the value is a country code' do
      let(:value) { 'FR' }

      it { is_expected.to eq({ value: 'FR' }) }
    end

    context 'when the value is a country name' do
      let(:value) { 'France' }

      it { is_expected.to eq({ value: 'France' }) }
    end

    context 'when the value is an unknown country code' do
      let(:value) { 'ZZ' }

      it { is_expected.to be_nil }
    end

    context 'when the value is not a country' do
      let(:value) { 'value' }

      it { is_expected.to be_nil }
    end

    context 'when the value is not a String' do
      let(:value) { ['FR'] }

      it { is_expected.to be_nil }
    end
  end
end
