# frozen_string_literal: true

describe APITokens::ScopesFieldsetComponent, type: :component do
  subject(:page) { render_inline(described_class.new(selected:, error:)) }

  let(:selected) { [APIToken::FORM_WRITE] }
  let(:error) { nil }

  it 'renders one checkbox per scope, checking the selected ones' do
    expect(page.css("input[type=checkbox][name='scopes[]']").map { it['value'] }).to eq(APIToken::SCOPES)
    expect(page.at_css("input[value=#{APIToken::FORM_WRITE}]")['checked']).to be_present
    expect(page.at_css("input[value=#{APIToken::APPLICATION_READ}]")['checked']).to be_nil
    expect(page.css('input[aria-describedby]')).to be_empty
    expect(page.at_css('fieldset')['aria-labelledby']).to eq('api-token-scopes-legend api-token-scopes-messages')
    expect(page.at_css('#api-token-scopes-messages')['aria-live']).to eq('polite')
    expect(page.at_css('.fr-message--error')).to be_nil
  end

  context 'with an error' do
    let(:error) { 'Sélectionnez au moins un droit' }

    it 'announces it in the messages group' do
      expect(page.at_css('fieldset')['role']).to eq('group')
      expect(page.at_css('#api-token-scopes-messages .fr-message--error').text).to eq(error)
    end
  end
end
