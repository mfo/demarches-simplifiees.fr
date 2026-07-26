# frozen_string_literal: true

RSpec.describe RenderCarteChampJob, type: :job do
  let(:types_de_champ_public) { [{ type: :carte }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:geo_areas) { [build(:geo_area, :selection_utilisateur, :polygon)] }
  let(:champ) { dossier.champ_data.first.tap { it.update(geo_areas:) } }

  let(:image) { 'rendered-image-bytes' }

  before { allow(StaticMapService).to receive(:render).and_return(image) }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(champ) }

    it 'attaches the rendered map to the champ' do
      expect { perform }.to change { champ.reload.static_map.attached? }.from(false).to(true)

      expect(champ.static_map.blob.download).to eq(image)
      expect(champ.static_map.blob.content_type).to eq('image/jpeg')
    end

    it 'does not queue the blob for virus scanning: the image comes from us' do
      perform

      blob = champ.reload.static_map.blob
      expect(blob).to be_processed
      expect(blob.virus_scan_result).to eq(ActiveStorage::VirusScanner::SAFE)
    end

    # The whole point of keeping it under its own attachment name: everything
    # that walks a champ's attachments walks piece_justificative_file.
    it 'does not attach the image as a piece justificative' do
      perform

      expect(champ.reload.piece_justificative_file).not_to be_attached
    end

    it 'renders the champ geometry' do
      expect(StaticMapService).to receive(:render).with(hash_including(type: 'FeatureCollection'))

      perform
    end

    context 'when the map is already up to date' do
      before { described_class.new.perform(champ) }

      it 'does not render again' do
        expect(StaticMapService).not_to receive(:render)

        described_class.new.perform(champ.reload)
      end
    end

    context 'when the geometry changed' do
      before { described_class.new.perform(champ) }

      it 'replaces the image rather than piling up attachments' do
        champ.reload.geo_areas.first.update!(geometry: { 'type' => 'Point', 'coordinates' => [2.4, 46.5] })

        expect { described_class.new.perform(champ.reload) }
          .to change { champ.reload.static_map.blob.id }

        expect(ActiveStorage::Attachment.where(record: champ, name: 'static_map').count).to eq(1)
      end
    end

    context 'when the champ has no geometry left' do
      before do
        described_class.new.perform(champ)
        champ.reload.geo_areas.destroy_all
      end

      it 'purges the stale image' do
        expect { described_class.new.perform(champ.reload) }
          .to change { champ.reload.static_map.attached? }.from(true).to(false)
      end
    end
  end

  describe '.digest' do
    let(:feature_collection) do
      {
        features: [
          { geometry: { type: 'Point', coordinates: [1, 2] }, properties: { source: 'selection_utilisateur' } },
        ],
      }
    end

    it 'ignores properties that do not affect the rendering' do
      renamed = feature_collection.deep_dup
      renamed[:features][0][:properties][:champ_label] = 'Nouveau libellé'

      expect(described_class.digest(renamed)).to eq(described_class.digest(feature_collection))
    end

    it 'changes when the geometry changes' do
      moved = feature_collection.deep_dup
      moved[:features][0][:geometry][:coordinates] = [3, 4]

      expect(described_class.digest(moved)).not_to eq(described_class.digest(feature_collection))
    end
  end
end
