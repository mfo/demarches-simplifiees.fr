# frozen_string_literal: true

describe DossierFilteringConcern do
  describe '.filter_ilike' do
    let(:dossier) { dossiers.en_construction }
    let(:scope) { Dossier.where(id: dossier.id).includes(:user) }

    def filtering(term) = scope.filter_ilike('user', 'email', [term]).ids

    it 'matches on a substring of the column' do
      expect(filtering('usager@exemple.fr')).to eq([dossier.id])
      expect(filtering('exemple')).to eq([dossier.id])
    end

    it 'escapes the ILIKE wildcards, so they match literally' do
      expect(filtering('usager%exemple.fr')).to eq([])
      expect(filtering('usager_exemple.fr')).to eq([])
    end

    # Quotes are neutralised by the bind parameter, not by sanitize_sql_like:
    # the payload stays inside the string literal it is bound into.
    it 'treats a quoted payload as data rather than SQL' do
      payload = "usager@exemple.fr%') UNION SELECT email, encrypted_password, id FROM users--"

      expect(filtering(payload)).to eq([])
    end
  end
end
