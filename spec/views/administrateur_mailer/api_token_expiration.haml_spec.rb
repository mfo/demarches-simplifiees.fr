# frozen_string_literal: true

describe 'administrateur_mailer/api_token_expiration', type: :view do
  let(:subject_text) { 'Expiration des jetons API' }
  let(:profil_link) { 'https://www.example.com/profil' }

  before do
    Current.application_name = 'Démarches Simplifiées'
    assign(:subject, subject_text)
    allow(view).to receive(:profil_url).and_return(profil_link)
  end

  after do
    Current.reset
  end

  context 'with a single token' do
    let(:tokens) { [Struct.new(:prefix).new('ABC123')] }

    before do
      assign(:tokens, tokens)
    end

    it 'renders the singular expiration message' do
      render

      expect(rendered).to include("Votre jeton d'API « ABC123 »")
      expect(rendered).to include(profil_link)
    end
  end

  context 'with multiple tokens' do
    let(:tokens) { [Struct.new(:prefix).new('ABC123'), Struct.new(:prefix).new('XYZ789')] }

    before do
      assign(:tokens, tokens)
    end

    it 'renders the plural expiration message' do
      render

      expect(rendered).to include("Vos jetons d'API « ABC123, XYZ789 »")
      expect(rendered).to include(profil_link)
    end
  end
end
