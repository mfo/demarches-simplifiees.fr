# frozen_string_literal: true

RSpec.describe APIIgn::API do
  describe '.wms_layers_for' do
    def bbox_spanning(meters)
      [275_000, 6_228_000, 275_000 + meters, 6_228_000 + meters]
    end

    it 'always asks for the aerial photography' do
      expect(described_class.wms_layers_for(bbox_spanning(500)))
        .to include(described_class::ORTHOPHOTOS_LAYER)
    end

    # At parcel scale, ADMINEXPRESS draws no place name at all: just a commune
    # boundary line cutting across the photo.
    it 'leaves out the administrative layer on a close-up' do
      expect(described_class.wms_layers_for(bbox_spanning(1_500)))
        .not_to include(described_class::ADMINEXPRESS_LAYER)
    end

    it 'adds the administrative layer once the extent is wide enough to carry place names' do
      expect(described_class.wms_layers_for(bbox_spanning(4_000)))
        .to include(described_class::ADMINEXPRESS_LAYER)
    end
  end
end
