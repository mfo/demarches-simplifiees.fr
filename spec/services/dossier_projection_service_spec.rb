# frozen_string_literal: true

describe DossierProjectionService do
  describe '#project' do
    subject { described_class.project(dossiers_ids, columns) }

    let(:procedure) { create(:procedure, public_type_de_champs:) }
    let(:public_type_de_champs) do
      [
        { type: :text, libelle: 'texte' },
        { type: :integer_number, libelle: 'nombre entier' },
      ]
    end
    let(:dossiers) { create_list(:dossier, 3, procedure:) }
    let(:dossiers_ids) { dossiers.take(2).map(&:id) }
    let(:text_column) { procedure.find_column(label: 'texte') }
    let(:columns) { [text_column] }

    it do
      projections = subject

      expect(projections.size).to eq(2)

      projection = projections.first
      expect(projection.dossier).to eq(dossiers.first)

      # only load the champ_data required for the columns
      expect(projection.champ_data.keys).to eq([text_column.stable_id])
    end

    context 'without champ columns' do
      let(:columns) { [procedure.dossier_id_column] }

      it { expect(subject.first.champ_data).to eq({}) }
    end
  end
end
