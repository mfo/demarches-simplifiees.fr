# frozen_string_literal: true

describe TypesDeChamp::FormattedTypeDeChamp do
  describe 'default options' do
    let(:type_de_champ) { create(:type_de_champ_formatted) }

    it 'are injected when loading a row whose options are empty' do
      TypeDeChamp.where(id: type_de_champ.id).update_all(options: {})

      reloaded = TypeDeChamp.find(type_de_champ.id)

      expect(reloaded.formatted_mode).to eq('simple')
      expect(reloaded.letters_accepted).to eq(true)
      expect(reloaded.numbers_accepted).to eq(true)
      expect(reloaded.special_characters_accepted).to eq(true)
    end

    it 'fill the missing keys of a new record built with some options' do
      tdc = TypeDeChamp.new(type_champ: 'formatted', options: { max_character_length: 10 })

      expect(tdc.formatted_mode).to eq('simple')
      expect(tdc.letters_accepted).to eq(true)
      expect(tdc.max_character_length).to eq(10)
    end

    it 'keep the explicit values of a new record' do
      tdc = TypeDeChamp.new(type_champ: 'formatted', options: { formatted_mode: 'advanced', letters_accepted: false })

      expect(tdc.formatted_mode).to eq('advanced')
      expect(tdc.letters_accepted).to eq(false)
      expect(tdc.numbers_accepted).to eq(true)
    end

    it 'do not add defaults to a persisted row that has options' do
      TypeDeChamp.where(id: type_de_champ.id).update_all(options: { max_character_length: 10 })

      reloaded = TypeDeChamp.find(type_de_champ.id)

      expect(reloaded.formatted_mode).to be_nil
      expect(reloaded.max_character_length).to eq(10)
    end

    it 'do not overwrite the persisted options' do
      type_de_champ.update!(formatted_mode: 'advanced', expression_reguliere: '\d+')

      reloaded = TypeDeChamp.find(type_de_champ.id)

      expect(reloaded.formatted_mode).to eq('advanced')
      expect(reloaded.expression_reguliere).to eq('\d+')
    end
  end
end
