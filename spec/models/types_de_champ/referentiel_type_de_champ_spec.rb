# frozen_string_literal: true

describe TypesDeChamp::ReferentielTypeDeChamp do
  describe "#referentiel_url_as_text" do
    let(:referentiel) do
      create(:api_referentiel, :exact_match).tap do |referentiel|
        referentiel.update!(url_tiptap: {
          "type" => "doc",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                { "type" => "text", "text" => "https://example.gouv.fr/?a=" },
                { "type" => "mention", "attrs" => { "id" => "1234", "label" => "Un autre champ" } },
                { "type" => "text", "text" => "&q=" },
                { "type" => "mention", "attrs" => { "id" => "{query}", "label" => "Valeur saisie par l'usager" } },
              ],
            },
          ],
        }, test_data_tiptap: { "{query}" => "PG46YY6YWCX8", "1234" => "42" })
      end
    end

    let(:type_de_champ) { create(:type_de_champ_referentiel, referentiel:) }

    it "renders every mention, not only {query}" do
      expect(type_de_champ.referentiel_url_as_text).to eq("https://example.gouv.fr/?a=1234&q={query}")
    end
  end
end
