# frozen_string_literal: true

RSpec.describe TagsButtonListComponent, type: :component do
  let(:tags) do
    {
      individual: TagsSubstitutionConcern::INDIVIDUAL_TAGS,
      etablissement: TagsSubstitutionConcern::ENTREPRISE_TAGS,
      dossier: TagsSubstitutionConcern::DOSSIER_TAGS,
      champ_public: [
        {
          id: 'tdc12',
          libelle: 'Votre avis',
          description: 'Détaillez votre avis',
        },
        {
          id: 'tdc13',
          libelle: 'Un champ facultatif',
          description: 'Ce champ est facultatif',
          maybe_null: true,
        },
        {
          id: 'tdc14',
          libelle: 'Un champ conditionnel',
          description: 'Ce champ est conditionnel',
          conditional: true,
        },
      ],

      champ_private: [
        {
          id: 'tdc22',
          libelle: 'Montant accordé',
        },
      ],
    }
  end

  let(:component) do
    described_class.new(tags:)
  end

  subject { render_inline(component).to_html }

  it 'renders' do
    expect(subject).to have_text("Identité")
    expect(subject).to have_text("civilité")
    expect(subject).to have_text("Votre avis")
    expect(subject).to have_text("Montant accordé")
  end

  it "hides optional and conditional tags by default" do
    expect(subject).to have_selector(".hidden button.fr-tag", text: "Un champ facultatif")
    expect(subject).to have_selector(".hidden button.fr-tag", text: "Un champ conditionnel")
    expect(subject).to have_selector(":not(.hidden) button.fr-tag", text: "Votre avis")
    expect(subject).to have_text("Voir les champs facultatifs et/ou conditionnels")
  end

  it "applies purple-glycine style to optional and conditional tags" do
    expect(subject).to have_selector("button.fr-tag.fr-tag--purple-glycine", text: "Un champ facultatif")
    expect(subject).to have_selector("button.fr-tag.fr-tag--purple-glycine", text: "Un champ conditionnel")
    expect(subject).not_to have_selector("button.fr-tag.fr-tag--purple-glycine", text: "Votre avis")
  end

  context "no optional or conditional champs" do
    let(:tags) do
      {
        champ_public: [
          { id: 'tdc12', libelle: 'Votre avis', description: '' },
        ],
      }
    end

    it { expect(subject).not_to have_text("Voir les champs facultatifs et conditionnels") }
  end
end
