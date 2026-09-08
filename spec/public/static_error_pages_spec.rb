# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

# The static pages in public/ are served by the reverse proxy or as a last
# resort by ErrorsController. When Turbo receives one of them as the response
# to a visit or a form submission, it swaps it into the current document, where
# the DSFR script of the previous page is still running and initialises the
# header components it finds. This checks the markup they rely on.
RSpec.describe 'static error pages' do
  pages = Dir[File.expand_path('../../public/*.html', __dir__)]

  pages.each do |path|
    describe File.basename(path) do
      subject(:header) { Nokogiri::HTML(File.read(path)).at_css('header.fr-header') }

      it 'gives DSFR HeaderLinks the menu container it copies the tools links into' do
        skip 'no DSFR header' if header.nil?

        if header.at_css('.fr-header__tools-links')
          expect(header.at_css('.fr-header__menu-links')).to be_present
        end
      end
    end
  end
end
