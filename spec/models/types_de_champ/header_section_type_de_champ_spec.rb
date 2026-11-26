# frozen_string_literal: true

describe TypesDeChamp::HeaderSectionTypeDeChamp do
  describe 'header_section_level validation' do
    subject(:tdc) { described_class.new(libelle: 'Titre', header_section_level: level) }

    [nil, '', 1, '2', 3].each do |valid|
      context "with #{valid.inspect}" do
        let(:level) { valid }

        it { expect(tdc.tap(&:validate).errors).not_to include(:header_section_level) }
      end
    end

    [0, 4, 9, '9', '-1', 'abc', '1.5'].each do |invalid|
      context "with #{invalid.inspect}" do
        let(:level) { invalid }

        it 'rejects it with the level message' do
          tdc.validate
          expect(tdc.errors).to include(:header_section_level)
          expect(tdc.errors.messages_for(:header_section_level)).to eq(['devrait être un niveau de titre valide (entier de 1 à 3)'])
        end
      end
    end

    context 'with a level out of range' do
      let(:level) { 9 }

      it { tdc.validate; expect(tdc.errors).to be_of_kind(:header_section_level, :in) }
    end

    context 'with a decimal' do
      let(:level) { '1.5' }

      it { tdc.validate; expect(tdc.errors).to be_of_kind(:header_section_level, :not_an_integer) }
    end
  end

  describe '#check_coherent_header_level' do
    let(:header) { described_class.new(header_section_level: 3) }
    let(:upper_tdcs) { [described_class.new(header_section_level: 1)] }

    it 'names the missing level' do
      expect(header.check_coherent_header_level(upper_tdcs)).to eq("devrait être précédé d’un titre de niveau 2")
    end
  end
end
