# frozen_string_literal: true

RSpec.describe Dossiers::ChampsRowsShowComponent, type: :component do
  let(:procedure) do
    create(:procedure, :published, types_de_champ_public: [
      { type: :repetition, libelle: "Titre bloc répétable", children: [{ type: :text, libelle: "Texte court" }] },
    ])
  end
  let(:dossier) { create(:dossier, procedure:, populate_champs: true) }
  let(:champs) { dossier.root_champs_public }

  before { render_inline(component).to_html }

  describe "repeatable block title heading hierarchy" do
    context "with default repetition_heading_level (h3)" do
      let(:component) do
        described_class.new(champs:, profile: "usager", seen_at: nil, repetition_heading_level: 3)
      end

      it "renders repeatable block titles as h3 for accessibility" do
        expect(page).to have_selector("h3.fr-h6.fr-text--bold", text: /Titre bloc répétable 1 :/)
        expect(page).to have_selector("h3.fr-h6.fr-text--bold", text: /Titre bloc répétable 2 :/)
      end
    end

    context "with repetition_heading_level 4" do
      let(:component) do
        described_class.new(champs:, profile: "usager", seen_at: nil, repetition_heading_level: 4)
      end

      it "renders repeatable block titles as h4" do
        expect(page).to have_selector("h4.fr-h6.fr-text--bold", text: /Titre bloc répétable 1 :/)
      end
    end
  end
end
