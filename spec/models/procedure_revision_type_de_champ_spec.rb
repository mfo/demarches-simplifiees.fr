# frozen_string_literal: true

describe ProcedureRevisionTypeDeChamp do
  describe '#upper_coordinates' do
    context 'when the coordinate is in a bloc bellow another coordinate' do
      let(:procedure) do
        create(:procedure,
               public_type_de_champs: [
                 { libelle: 'l1' },
                 {
                   type: :repetition, children: [
                     { libelle: 'l2.1' },
                     { libelle: 'l2.2' },
                   ],
                 },
               ])
      end

      let(:l2_2) do
        procedure
          .draft_revision
          .revision_type_de_champs.joins(:type_de_champ)
          .find_by(type_de_champ: { libelle: 'l2.2' })
      end

      it { expect(l2_2.upper_coordinates.map(&:libelle)).to match_array(["l1", "l2.1"]) }
    end

    context 'when the coordinate is an annotation' do
      let(:procedure) do
        create(:procedure,
               private_type_de_champs: [
                 { libelle: 'a1' },
                 { libelle: 'a2' },
               ],
               public_type_de_champs: [
                 { libelle: 'l1' },
                 {
                   type: :repetition, libelle: 'l2', children: [
                     { libelle: 'l2.1' },
                     { libelle: 'l2.2' },
                   ],
                 },
               ])
      end

      let(:a2) do
        procedure
          .draft_revision
          .revision_type_de_champs.joins(:type_de_champ)
          .find_by(type_de_champ: { libelle: 'a2' })
      end

      it { expect(a2.upper_coordinates.map(&:libelle)).to match_array(["l1", "l2", "a1"]) }
    end
  end
end
