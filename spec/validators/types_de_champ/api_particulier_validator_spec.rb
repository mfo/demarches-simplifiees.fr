# frozen_string_literal: true

RSpec.describe TypesDeChamp::APIParticulierValidator do
  subject { procedure.validate(:types_de_champ_public_editor) }

  context 'when procedure has a API Particulier champ and a API Particulier token' do
    let(:procedure) { create(:procedure, :with_api_particulier_token, public_type_de_champs:) }
    let(:public_type_de_champs) { [{ type: :quotient_familial }] }

    it 'does not add errors to the procedure' do
      subject
      expect(procedure.errors).to be_empty
    end
  end

  context 'when procedure has a API Particulier champ but no API Particulier token' do
    let(:procedure) { create(:procedure, public_type_de_champs:) }
    let(:public_type_de_champs) { [{ type: :quotient_familial }] }

    it 'adds errors to the procedure' do
      subject
      expect(procedure.errors.details[:public_draft_type_de_champs])
        .to include(hash_including(error: :missing_api_particulier_token))
    end
  end
end
