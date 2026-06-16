# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dsfr::CalloutComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(title: "Mon titre", theme:)) }

  context "with the orange_terre_battue theme" do
    let(:theme) { :orange_terre_battue }

    it { is_expected.to have_css(".fr-callout.fr-callout--orange-terre-battue") }
  end

  context "with the warning theme" do
    let(:theme) { :warning }

    it { is_expected.to have_css(".fr-callout.fr-callout--brown-caramel") }
  end
end
