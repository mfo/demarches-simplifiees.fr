# frozen_string_literal: true

describe TypesDeChampEditor::EditorComponent, type: :component do
  let(:revision) { procedure.draft_revision }
  let(:procedure) { create(:procedure, private_type_de_champs:, public_type_de_champs:) }
  let(:private_type_de_champs) { [{ type: :repetition, children: [], libelle: 'private' }] }
  let(:public_type_de_champs) { [{ type: :repetition, children: [], libelle: 'public' }] }

  describe 'render' do
    subject { render_inline(described_class.new(revision:, is_annotation:)) }

    context 'public_type_de_champs' do
      let(:is_annotation) { false }

      it 'does not render private champs errors' do
        expect(subject).not_to have_text("private")
        expect(subject).to have_selector("a", text: "public")
        expect(subject).to have_text("doit comporter au moins un champ répétable")
      end
    end

    context 'private_type_de_champs' do
      let(:is_annotation) { true }

      it 'does not render public champs errors' do
        expect(subject).to have_selector("a", text: "private")
        expect(subject).to have_text("doit comporter au moins un champ répétable")
        expect(subject).not_to have_text("public")
      end
    end
  end
end
