# frozen_string_literal: true

describe IndifferentJsonbType do
  let(:type) { described_class.new }

  describe '#deserialize' do
    it 'loads a NULL column as an empty hash' do
      expect(type.deserialize(nil)).to eq({})
    end

    it 'gives indifferent access to the loaded hash' do
      expect(type.deserialize('{"key":"value"}')[:key]).to eq('value')
    end
  end

  describe '#cast' do
    it 'casts nil to an empty hash' do
      expect(type.cast(nil)).to eq({})
    end

    it 'gives indifferent access to the cast hash' do
      expect(type.cast({ 'key' => 'value' })[:key]).to eq('value')
    end
  end

  context 'on the type de champ options' do
    it 'loads a NULL column as an empty hash' do
      type_de_champ = create(:type_de_champ_text)
      type_de_champ.update_column(:options, nil)
      type_de_champ = TypeDeChamp.find(type_de_champ.id)

      expect(type_de_champ.options).to eq({})
      expect(type_de_champ.clean_options).to eq({})
    end

    it 'does not mark a stored empty hash as changed' do
      type_de_champ = create(:type_de_champ_text)
      type_de_champ.update_column(:options, {})
      type_de_champ = TypeDeChamp.find(type_de_champ.id)
      type_de_champ.options

      expect(type_de_champ.changed?).to be(false)
    end
  end
end
