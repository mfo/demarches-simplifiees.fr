# frozen_string_literal: true

RSpec.describe Dossiers::GeoAreaComponent, type: :component do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :carte }]) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first }
  let(:geo_area) { create(:geo_area, :selection_utilisateur, :polygon, champ:) }

  before { render_inline(described_class.new(geo_area:, editing:)) }

  shared_examples 'exposes the geojson feature id' do
    it "matches the id of the map's geojson feature so clicking it can zoom to the right shape" do
      expect(page.find("[data-controller='geo-area']")['data-geo-area-id-value'])
        .to eq(geo_area.to_feature[:properties][:id])
    end
  end

  context 'when editing' do
    let(:editing) { true }

    include_examples 'exposes the geojson feature id'
  end

  context 'when not editing' do
    let(:editing) { false }

    include_examples 'exposes the geojson feature id'
  end
end
