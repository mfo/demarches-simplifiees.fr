# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillDatetimeTypeDeChamp do
  let(:procedure) { build(:procedure) }
  let(:type_de_champ) { build(:type_de_champ_datetime, procedure: procedure) }
  let(:champ) { Champs::DatetimeChamp.new }

  describe 'ancestors' do
    subject { described_class.build(type_de_champ, procedure.active_revision) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#to_assignable_attributes' do
    subject(:to_assignable_attributes) { described_class.build(type_de_champ, procedure.active_revision).to_assignable_attributes(champ, value) }

    context 'when the value is an ISO8601 datetime' do
      let(:value) { '2022-12-22T10:30' }

      it { is_expected.to eq({ value: Time.zone.parse('2022-12-22T10:30').iso8601 }) }
    end

    context 'when the value is not a datetime' do
      let(:value) { 'value' }

      it { is_expected.to be_nil }
    end

    context 'when the value is a wrongly formatted datetime' do
      let(:value) { '12-22-2022T10:30' }

      it { is_expected.to be_nil }
    end

    context 'when the value is not a String' do
      let(:value) { { "injected" => "x" } }

      it { is_expected.to be_nil }
    end

    context 'when the type de champ expects a date in the past' do
      before { type_de_champ.date_in_past = '1' }

      context 'and the datetime is in the past' do
        let(:value) { '2000-01-01T10:30' }

        it { is_expected.to eq({ value: Time.zone.parse('2000-01-01T10:30').iso8601 }) }
      end

      context 'and the datetime is not in the past' do
        let(:value) { 1.day.from_now.iso8601 }

        it { is_expected.to be_nil }
      end
    end
  end
end
