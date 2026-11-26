# frozen_string_literal: true

describe Logic::ErrorMessages do
  include Logic

  # the translations use non-breaking spaces
  subject { described_class.new(condition, source_tdcs).to_a.map { it.gsub(/[[:space:]]/, ' ') } }

  let(:source_tdcs) { [tdc] }
  let(:tdc) { build(:type_de_champ_integer_number) }

  context 'without condition' do
    let(:condition) { nil }

    it { is_expected.to eq([]) }
  end

  context 'with a valid condition' do
    let(:condition) { ds_eq(champ_value(tdc.stable_id), constant(1)) }

    it { is_expected.to eq([]) }
  end

  context 'when the targeted champ is not available' do
    let(:source_tdcs) { [] }
    let(:condition) { ds_eq(champ_value(tdc.stable_id), constant(1)) }

    it { is_expected.to eq(["Un champ cible n’est plus disponible. Il est soit supprimé, soit déplacé en dessous de ce champ."]) }
  end

  context 'when the types mismatch' do
    let(:condition) { ds_eq(champ_value(tdc.stable_id), constant('a')) }

    it { is_expected.to eq(["Le champ « #{tdc.libelle} » est de type « nombre entier ». Il ne peut pas être égal à « a »."]) }

    context 'in English' do
      around { |example| I18n.with_locale(:en) { example.run } }

      it { is_expected.to eq(["The field ‘#{tdc.libelle}’ is a ‘integer number’. It cannot be equal to ‘a’."]) }
    end
  end

  context 'when the rows are contradictory' do
    let(:condition) { ds_and([greater_than(champ_value(tdc.stable_id), constant(3)), less_than(champ_value(tdc.stable_id), constant(2))]) }

    it { is_expected.to eq(["Aucune valeur du champ « #{tdc.libelle} » ne vérifie à la fois « supérieur à 3 » et « inférieur à 2 »."]) }
  end
end
