# frozen_string_literal: true

RSpec.describe Referentiels::ConfigurationErrorComponent, type: :component do
  let(:component) { described_class.new(referentiel:, type_de_champ:, procedure:) }
  let(:procedure) { create(:procedure, public_type_de_champs:) }
  let(:public_type_de_champs) { [{ type: :referentiel, referentiel: }] }
  let(:type_de_champ) { procedure.draft_revision.public_root_type_de_champs.first }
  let(:referentiel) { create(:api_referentiel, :exact_match) }
  before do
    render_inline(component)
  end
  context 'when referentiel is not ready' do
    it 'render error' do
      expect(page).to have_text(component.error_title)
      expect(page).to have_selector("button.fr-btn[disabled]")
    end
  end
end
