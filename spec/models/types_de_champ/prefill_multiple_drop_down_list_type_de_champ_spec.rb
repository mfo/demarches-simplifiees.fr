# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillMultipleDropDownListTypeDeChamp do
  let(:procedure) { create(:procedure) }

  describe 'ancestors' do
    subject { described_class.new(build(:type_de_champ_multiple_drop_down_list, procedure: procedure), procedure.active_revision) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillDropDownListTypeDeChamp) }
  end

  describe '#example_value' do
    let(:type_de_champ) { build(:type_de_champ_multiple_drop_down_list, drop_down_options_from_text: drop_down_options_from_text, procedure: procedure) }
    subject(:example_value) { described_class.new(type_de_champ, procedure.active_revision).example_value }

    context 'when the multiple drop down list has no option' do
      let(:drop_down_options_from_text) { "" }

      it { expect(example_value).to eq(["Fromage", "Dessert"]) }
    end

    context 'when the multiple drop down list only has one option' do
      let(:drop_down_options_from_text) { "value" }

      it { expect(example_value).to eq("value") }
    end

    context 'when the multiple drop down list has two options or more' do
      let(:drop_down_options_from_text) { "value1\r\nvalue2\r\nvalue3" }

      it { expect(example_value).to eq(["value1", "value2"]) }
    end
  end

  describe '#to_assignable_attributes' do
    let(:type_de_champ) { build(:type_de_champ_multiple_drop_down_list, procedure: procedure) }
    let(:champ) { Champs::MultipleDropDownListChamp.new }
    subject(:to_assignable_attributes) { described_class.build(type_de_champ, procedure.active_revision).to_assignable_attributes(champ, value) }

    context 'when all the values are in the options' do
      let(:value) { ["val1", "val2"] }

      it { is_expected.to eq({ value: ["val1", "val2"] }) }
    end

    context 'when the value is a single option' do
      let(:value) { "val1" }

      it { is_expected.to eq({ value: "val1" }) }
    end

    context 'when a value is not in the options' do
      let(:value) { ["value"] }

      it { is_expected.to be_nil }
    end

    context 'when the value contains a Hash (malicious input)' do
      let(:value) { [{ "injected" => "x" }] }

      it { is_expected.to be_nil }
    end
  end
end
