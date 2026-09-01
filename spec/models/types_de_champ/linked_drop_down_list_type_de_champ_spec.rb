# frozen_string_literal: true

describe TypesDeChamp::LinkedDropDownListTypeDeChamp do
  # On creation (type_champ_changed?) set_drop_down_list_options would overwrite an invalid menu.
  let(:type_de_champ) { create(:type_de_champ_linked_drop_down_list).tap { _1.drop_down_options = menu_options } }

  subject { type_de_champ }

  describe '#unpack_options' do
    context 'with no options' do
      let(:menu_options) { [] }
      it do
        expect(subject.secondary_options).to eq({})
        expect(subject.primary_options).to eq([])
      end
    end

    context 'with two primary options' do
      let(:menu_options) do
        [
          "--Primary 1--",
          "secondary 1.1",
          "secondary 1.2",
          "--Primary 2--",
          "secondary 2.1",
          "secondary 2.2",
          "secondary 2.3",
        ]
      end

      context "mandatory tdc" do
        it do
          expect(subject.secondary_options).to eq(
            {
              'Primary 1' => ['secondary 1.1', 'secondary 1.2'],
              'Primary 2' => ['secondary 2.1', 'secondary 2.2', 'secondary 2.3'],
            }
          )
          expect(subject.primary_options).to eq(['Primary 1', 'Primary 2'])
        end
      end

      context "not mandatory" do
        let(:type_de_champ) { build(:type_de_champ_linked_drop_down_list, drop_down_options: menu_options, mandatory: false) }

        it do
          expect(subject.secondary_options).to eq(
            {
              'Primary 1' => ['secondary 1.1', 'secondary 1.2'],
              'Primary 2' => ['secondary 2.1', 'secondary 2.2', 'secondary 2.3'],
            }
          )
          expect(subject.primary_options).to eq(['Primary 1', 'Primary 2'])
        end
      end
    end
  end
end
