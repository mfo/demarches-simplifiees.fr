# frozen_string_literal: true

describe RevisionDescribableToLLMConcern do
  describe "#schema_to_llm" do
    context 'when a type_de_champ has nil options' do
      let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :date, libelle: "Date de naissance" }]) }
      let(:revision) { procedure.draft_revision }

      before do
        revision.public_root_type_de_champs.first.update_column(:options, nil)
      end

      it 'does not raise' do
        expect { revision.schema_to_llm }.not_to raise_error
      end
    end
  end
end
