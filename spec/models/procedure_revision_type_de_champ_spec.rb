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

  describe '#prefill_target_coordinates' do
    let(:procedure) do
      create(:procedure,
             public_type_de_champs: [
               { libelle: 'p1' },
               { libelle: 'p2' },
               {
                 type: :repetition, libelle: 'p3', children: [
                   { libelle: 'p3.1' },
                   { libelle: 'p3.2' },
                 ],
               },
             ],
             private_type_de_champs: [
               { libelle: 'a1' },
               { libelle: 'a2' },
             ])
    end

    def coordinate(libelle)
      procedure
        .draft_revision
        .revision_type_de_champs.joins(:type_de_champ)
        .find_by(type_de_champ: { libelle: })
    end

    subject { coordinate(from).prefill_target_coordinates.map(&:libelle) }

    context 'from a public champ at root' do
      let(:from) { 'p1' }

      it 'takes the public coordinates after it, a repetition bringing its children, plus every annotation' do
        expect(subject).to match_array(['p2', 'p3', 'p3.1', 'p3.2', 'a1', 'a2'])
      end
    end

    context 'from a public champ inside a repetition' do
      let(:from) { 'p3.1' }

      it 'stays within its own row, plus every annotation' do
        expect(subject).to match_array(['p3.2', 'a1', 'a2'])
      end
    end

    context 'from an annotation' do
      let(:from) { 'a1' }

      it 'takes no public champ' do
        expect(subject).to match_array(['a2'])
      end

      context 'when the procedure may prefill public champs from an annotation' do
        before { Flipper.enable(:annotation_prefill_champs_public, procedure) }

        # p1 est avant l'annotation dans son propre bloc : sa position ne doit pas
        # être comparée à celle de l'annotation, qui vit dans l'autre bloc.
        it 'takes every public champ, whatever its position' do
          expect(subject).to match_array(['p1', 'p2', 'p3', 'p3.1', 'p3.2', 'a2'])
        end
      end
    end
  end
end
