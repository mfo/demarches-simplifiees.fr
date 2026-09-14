# frozen_string_literal: true

describe TypesDeChampEditor::InfoReferentielComponent, type: :component do
  describe 'render' do
    let(:component) { described_class.new(procedure:, type_de_champ:) }
    let(:procedure) { create(:procedure, :published, public_type_de_champs: [{ type: :referentiel }]) }
    let(:type_de_champ) { procedure.draft_revision.public_root_type_de_champs.first }
    let(:edit_path) { Rails.application.routes.url_helpers.edit_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id) }

    before do
      referentiel
      render_inline(component)
    end

    context 'having referentiel' do
      let(:referentiel) { create(:api_referentiel, :exact_match, type_de_champs: [type_de_champ]) }

      it "links to the champ's referentiel, which the controller duplicates on write" do
        expect(page).to have_link("Configurer le champ", href: edit_path)
      end
    end

    context 'not having referentiel' do
      let(:referentiel) { nil }

      it "links to the same form, which builds the referentiel" do
        expect(page).to have_link("Configurer le champ", href: edit_path)
      end
    end
  end
end
