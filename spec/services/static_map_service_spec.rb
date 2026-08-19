# frozen_string_literal: true

RSpec.describe StaticMapService do
  let(:polygon) do
    {
      type: 'Feature',
      properties: { source: 'selection_utilisateur' },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [2.47312545776367, 48.72845439491962],
            [2.4759578704834, 48.72955840196789],
            [2.47715950012207, 48.72771837675469],
            [2.47308254241943, 48.7276900681486],
            [2.47312545776367, 48.72845439491962],
          ],
        ],
      },
    }
  end

  let(:feature_collection) { { type: 'FeatureCollection', features: [polygon] } }

  it 'refuses to render an empty map' do
    expect { described_class.render({ type: 'FeatureCollection', features: [] }) }
      .to raise_error(StaticMapService::EmptyGeometryError)
  end

  # The application's GeoJSON schema accepts GeometryCollection, which the
  # service cannot walk. Without a guard, computing the extent blew up with a
  # NoMethodError, retried 25 times by ApplicationJob.
  it 'refuses to render a geometry it cannot walk' do
    feature_collection = {
      type: 'FeatureCollection',
      features: [{ type: 'Feature', properties: {}, geometry: { type: 'GeometryCollection', geometries: [] } }],
    }

    expect { described_class.render(feature_collection) }
      .to raise_error(StaticMapService::EmptyGeometryError)
  end

  # Compositing goes through libvips, absent from the default CI job.
  describe '.render', :external_deps do
    # An opaque black PNG, good enough as a basemap: the assertions are about
    # what the service draws, not about the background's content.
    let(:tile) { Vips::Image.black(200, 200).write_to_buffer('.png') }

    subject(:image) { Vips::Image.new_from_buffer(described_class.render(feature_collection, size: 200), '') }

    before do
      require "vips"
      allow(APIIgn::API).to receive(:fetch_wms_layers).and_return([tile])
    end

    it 'renders a square image at the requested size' do
      expect(image.width).to eq(200)
      expect(image.height).to eq(200)
    end

    it 'draws the geometry over the background' do
      # The background is black: any non-black pixel comes from what the service draws.
      expect(image.max).to be > 0
    end

    it 'accepts string keys' do
      expect { described_class.render(feature_collection.deep_stringify_keys, size: 200) }.not_to raise_error
    end
  end

  describe 'bounding box' do
    subject(:bbox) { described_class.new(feature_collection).send(:bbox) }

    it 'is square' do
      min_x, min_y, max_x, max_y = bbox
      expect(max_x - min_x).to be_within(0.001).of(max_y - min_y)
    end

    it 'contains the geometry with a margin' do
      min_x, min_y, max_x, max_y = bbox
      # South-west corner of the geometry, projected.
      x, y = described_class.new(feature_collection).send(:project, [2.47308254241943, 48.7276900681486])

      expect(x).to be > min_x
      expect(y).to be > min_y
      expect(x).to be < max_x
      expect(y).to be < max_y
    end

    context 'with a single point' do
      let(:feature_collection) do
        {
          type: 'FeatureCollection',
          features: [{ type: 'Feature', properties: {}, geometry: { type: 'Point', coordinates: [2.4745, 48.7281] } }],
        }
      end

      it 'falls back to a fixed radius rather than a zero-sized extent' do
        min_x, _min_y, max_x, _max_y = bbox
        expect(max_x - min_x).to be > 0
      end
    end
  end

  describe 'projection' do
    subject(:service) { described_class.new(feature_collection) }

    # Reference values for EPSG:4326 -> EPSG:3857, computed outside this code
    # (R·λ and R·atanh(sin φ), the equivalent form of the formula used here).
    it 'projects to web mercator' do
      x, y = service.send(:project, [2.4745, 48.7281])

      expect(x).to be_within(0.01).of(275_460.0800)
      expect(y).to be_within(0.01).of(6_228_850.9549)
    end

    it 'clamps latitudes beyond the mercator limit' do
      expect { service.send(:project, [0, 90]) }.not_to raise_error
    end
  end

  describe 'styling' do
    subject(:svg) { described_class.new(feature_collection).send(:svg) }

    it 'styles user selections in the selection colour' do
      expect(svg).to include('fill="#FFD400"')
    end

    context 'with a cadastre parcel' do
      let(:polygon) { super().deep_merge(properties: { source: 'cadastre' }) }

      it 'styles it like a highlighted parcel' do
        expect(svg).to include('fill="#018100"')
      end

      # The green is what tells a parcel from the référentiel apart from what
      # the usager drew by hand, so it must not pick up the selection casing.
      it 'gets no casing' do
        expect(svg).not_to include('#1F1A00')
      end
    end

    context 'with a line drawn by the user' do
      let(:polygon) do
        {
          type: 'Feature',
          properties: { source: 'selection_utilisateur' },
          geometry: { type: 'LineString', coordinates: [[2.4735, 48.7290], [2.4750, 48.7298]] },
        }
      end

      it 'uses the selection colour and no fill' do
        expect(svg).to include('stroke="#FFD400"').and include('fill="none"')
      end

      # The casing is what makes the mark readable over water or woodland; it
      # only works if it is drawn first, under the bright stroke.
      it 'draws a dark casing under the stroke' do
        expect(svg.index('stroke="#1F1A00"')).to be < svg.index('stroke="#FFD400"')
      end
    end

    context 'with a point drawn by the user' do
      let(:polygon) do
        {
          type: 'Feature',
          properties: { source: 'selection_utilisateur' },
          geometry: { type: 'Point', coordinates: [2.4735, 48.7290] },
        }
      end

      # Points used to be red while lines and areas were not: one colour for
      # everything the usager drew is the whole point of the scheme.
      it 'uses the selection colour, ringed by the casing' do
        expect(svg).to include('<circle').and include('fill="#FFD400"').and include('stroke="#1F1A00"')
      end
    end

    it 'burns in the IGN attribution' do
      expect(svg).to include('IGN')
    end
  end
end
