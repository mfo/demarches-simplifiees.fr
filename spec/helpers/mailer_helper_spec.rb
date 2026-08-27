# frozen_string_literal: true

RSpec.describe MailerHelper, type: :helper do
  describe '#dsfr_button' do
    it 'renders primary button with DSFR markup' do
      result = helper.dsfr_button('Voir le dossier', 'https://example.com/dossier', :primary)
      expect(result).to include('darkmode-button-primary')
      expect(result).to include('darkmode-button-color-primary')
      expect(result).to include('Voir le dossier')
      expect(result).to include('https://example.com/dossier')
      expect(result).to include('bgcolor="#000091"')
      expect(result).to include('color: #FFFFFF')
    end

    it 'renders secondary button with DSFR markup' do
      result = helper.dsfr_button('Répondre', 'https://example.com/reply', :secondary)
      expect(result).to include('darkmode-button-secondary')
      expect(result).to include('darkmode-button-color-secondary')
      expect(result).to include('Répondre')
      expect(result).to include('border:solid 1px #000091')
      expect(result).to include('color: #000091')
    end
  end

  describe '#application_name_without_link' do
    subject { helper.application_name_without_link }

    it 'inserts a WORD JOINER before each dot, so mail clients do not auto-link the name' do
      expect(subject).to eq(APPLICATION_NAME.gsub('.', "\u2060."))
      expect(subject.delete("\u2060")).to eq(APPLICATION_NAME)
    end

    it 'carries no markup, so ERB escaping leaves it untouched' do
      expect(ERB::Util.html_escape(subject)).to eq(subject)
    end
  end
end
