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

  describe 'a legacy level out of range' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :header_section, libelle: 'Titre' }]) }
    let(:header) { procedure.draft_revision.public_root_type_de_champs.first.tap { it.update_columns(options: { header_section_level: '9' }) }.reload }

    it 'stays valid when only the libelle changes' do
      header.libelle = 'Autre titre'
      expect(header).to be_valid
    end

    it 'is rejected when the level is changed to another invalid one' do
      header.header_section_level = '4'
      header.validate
      expect(header.errors).to be_of_kind(:header_section_level, :in)
      expect(header.errors.full_messages.first).to include('Niveau du titre')
    end

    it 'keeps its copy valid' do
      expect(header.deep_clone).to be_valid
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
