# frozen_string_literal: true

describe Profile::APITokenComponent, type: :component do
  let(:api_token) { APIToken.generate(administrateurs.default).first }

  subject { render_inline(described_class.new(api_token:)).text }

  it 'lists the scopes of the token' do
    api_token.update!(scopes: [APIToken::APPLICATION_READ, APIToken::FORM_WRITE])

    expect(subject).to include('lecture des dossiers et édition des formulaires (brouillons) sur')
  end

  it 'shows the rights of a legacy token' do
    expect(subject).to include('lecture des dossiers et écriture des dossiers sur')
  end
end
