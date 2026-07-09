# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillDepartementTypeDeChamp, type: :model do
  let(:procedure) { create(:procedure) }
  let(:type_de_champ) { build(:type_de_champ_departements, procedure: procedure) }

  describe 'ancestors' do
    subject { described_class.build(type_de_champ, procedure.active_revision) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#possible_values' do
    let(:expected_values) {
      "Un <a href=\"https://fr.wikipedia.org/wiki/Num%C3%A9rotation_des_d%C3%A9partements_fran%C3%A7ais\" target=\"_blank\">numéro de département</a><br><a title=\"Toutes les valeurs possibles — Nouvel onglet\" target=\"_blank\" rel=\"noopener noreferrer\" href=\"/procedures/#{procedure.path}/prefill_type_de_champs/#{type_de_champ.id}\">Voir toutes les valeurs possibles</a>"
    }
    subject(:possible_values) { described_class.new(type_de_champ, procedure.active_revision).possible_values }

    before { type_de_champ.reload }

    it { expect(possible_values).to match(expected_values) }
  end

  describe '#to_assignable_attributes' do
    let(:champ) { Champs::DepartementChamp.new }
    subject(:to_assignable_attributes) { described_class.build(type_de_champ, procedure.active_revision).to_assignable_attributes(champ, value) }

    context 'when the value is a departement code' do
      let(:value) { '01' }

      it { is_expected.to eq({ value: '01' }) }
    end

    context 'when the value is a 3-characters departement code' do
      let(:value) { '971' }

      it { is_expected.to eq({ value: '971' }) }
    end

    context 'when the value is a departement name' do
      let(:value) { 'Aisne' }

      it { is_expected.to eq({ value: 'Aisne' }) }
    end

    context 'when the value is an unknown departement code' do
      let(:value) { '00' }

      it { is_expected.to be_nil }
    end

    context 'when the value is not a departement' do
      let(:value) { 'value' }

      it { is_expected.to be_nil }
    end

    context 'when the value is not a String' do
      let(:value) { ['01'] }

      it { is_expected.to be_nil }
    end
  end
end
