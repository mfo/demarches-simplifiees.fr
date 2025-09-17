# frozen_string_literal: true

require 'rails_helper'

describe 'administrateur_mailer/api_token_expiration', type: :view do
  let(:profil_link) { 'https://example.test/profil' }

  before do
    assign(:subject, 'Expiration des jetons API')
    allow(view).to receive(:profil_url).and_return(profil_link)
    Current.application_name = 'Démarches Simplifiées'
  end

  after { Current.reset_all }

  context 'with a single token' do
    before { assign(:tokens, [OpenStruct.new(prefix: 'ABC123')]) }

    it 'renders the singular expiration message' do
      render template: 'administrateur_mailer/api_token_expiration'

      expect(rendered).to include('ABC123')
    end
  end

  context 'with multiple tokens' do
    before { assign(:tokens, [OpenStruct.new(prefix: 'ABC123'), OpenStruct.new(prefix: 'XYZ789')]) }

    it 'renders the plural expiration message' do
      render template: 'administrateur_mailer/api_token_expiration'

      expect(rendered).to include('ABC123')
      expect(rendered).to include('XYZ789')
    end
  end
end
