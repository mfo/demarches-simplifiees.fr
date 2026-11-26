# frozen_string_literal: true

describe ConditionForm, type: :model do
  include Logic

  describe 'to_condition' do
    let(:top_operator_name) { '' }
    let(:champ_value_type) { :number }

    subject { ConditionForm.new(rows: rows, top_operator_name: top_operator_name).to_condition }

    before do
      allow_any_instance_of(Logic::ChampValue).to receive(:type).and_return(champ_value_type)
    end

    context 'when a row is added' do
      let(:rows) { [{ targeted_champ: champ_value(1).to_json, operator_name: Logic::Eq.name, value: '1' }] }
      it { is_expected.to eq(ds_eq(champ_value(1), constant(1))) }

      context 'with a targeted enum' do
        let(:champ_value_type) { :enum }

        it { is_expected.to eq(ds_eq(champ_value(1), constant('1'))) }
      end
    end

    context 'when two rows are added' do
      let(:top_operator_name) { Logic::And.name }
      let(:rows) do
        [
          { targeted_champ: champ_value(1).to_json, operator_name: Logic::Eq.name, value: '2' },
          { targeted_champ: champ_value(3).to_json, operator_name: Logic::GreaterThan.name, value: '4' },
        ]
      end

      let(:expected) do
        ds_and([
          ds_eq(champ_value(1), constant(2)),
          greater_than(champ_value(3), constant(4)),
        ])
      end
      it { is_expected.to eq(expected) }
    end

    context 'when 3 rows are added' do
      let(:top_operator_name) { Logic::Or.name }
      let(:rows) do
        [
          { targeted_champ: champ_value(1).to_json, operator_name: Logic::Eq.name, value: '2' },
          { targeted_champ: champ_value(3).to_json, operator_name: Logic::GreaterThan.name, value: '4' },
          { targeted_champ: champ_value(5).to_json, operator_name: Logic::LessThan.name, value: '6' },
        ]
      end

      let(:expected) do
        ds_or([
          ds_eq(champ_value(1), constant(2)),
          greater_than(champ_value(3), constant(4)),
          less_than(champ_value(5), constant(6)),
        ])
      end
      it { is_expected.to eq(expected) }
    end
  end

  describe 'with raw values' do
    let(:number_tdc) { build(:type_de_champ_integer_number, stable_id: 12) }
    let(:enum_tdc) { build(:type_de_champ_drop_down_list, stable_id: 13) }
    let(:source_tdcs) { [number_tdc, enum_tdc] }
    let(:form) { ConditionForm.new(source_tdcs:) }

    it 'parses the value as a number for a number target' do
      expect(form.condition_from_raw(12, Logic::GreaterThan.name, '4')).to eq(greater_than(champ_value(12), constant(4)))
    end

    it 'keeps a string constant for an enum target' do
      expect(form.condition_from_raw(13, Logic::Eq.name, '4')).to eq(ds_eq(champ_value(13), constant('4')))
    end

    it 'builds an empty right term for a blank value' do
      expect(form.condition_from_raw(12, Logic::Eq.name, '')).to eq(ds_eq(champ_value(12), empty))
    end

    it 'targets a column when a column_id is given' do
      condition = form.condition_from_raw(12, Logic::Eq.name, '4', column_id: 'value')

      expect(condition.left).to be_a(Logic::ChampColumnValue)
      expect(condition.left.stable_id).to eq(12)
    end

    it 'reports an unknown target through the condition errors' do
      condition = form.condition_from_raw(99, Logic::Eq.name, '4')

      expect(condition.errors(source_tdcs)).to include({ type: :not_available })
    end

    it 'never reads the value as a serialized term' do
      value = champ_value(13).to_json

      expect(form.condition_from_raw(12, Logic::Eq.name, value).right).to eq(constant(value))
    end

    it 'rejects an operator name that is not a binary operator' do
      ['Logic::Foo', Logic::And.name, Logic::ChampColumnValue.name].each do |name|
        expect { form.condition_from_raw(12, name, '4') }.to raise_error(ArgumentError, /unknown operator/)
      end
    end
  end
end
