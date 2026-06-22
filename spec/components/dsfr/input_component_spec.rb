# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dsfr::InputComponent, type: :component do
  def render_with_form(attribute:, **component_options)
    cmp = nil
    ActionView::Base.empty.form_with(model: procedure, url: "/fake") do |form|
      cmp = described_class.new(form:, attribute:, **component_options)
    end
    render_inline(cmp).to_html
  end

  let(:procedure) { build_stubbed(:procedure) }

  context "with a password_field whose attribute has a dedicated aria_label translation" do
    let(:html) { render_with_form(attribute: :api_entreprise_token, input_type: :password_field, required: false) }

    it "uses the attribute-specific aria_label" do
      expect(html).to include('aria-label="Afficher le jeton API Entreprise"')
      expect(html).not_to include("translation_missing")
    end
  end

  context "with a password_field whose attribute has no dedicated aria_label translation" do
    let(:html) { render_with_form(attribute: :libelle, input_type: :password_field, required: false) }

    it "falls back to the default aria_label without leaking a missing-translation span" do
      expect(html).to include('aria-label="Afficher"')
      expect(html).not_to include("translation_missing")
    end
  end
end
