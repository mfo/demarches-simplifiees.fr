# frozen_string_literal: true

RSpec.describe WatermarkService, :external_deps do
  let(:image) { file_fixture("logo_test_procedure.png") }
  let(:watermark_service) { WatermarkService.new }

  describe '#process' do
    it 'returns a tempfile if watermarking succeeds' do
      Tempfile.create(["watermarked", ".png"]) do |output|
        watermark_service.process(image, output)
        # output size should always be a little greater than input size
        expect(output.size).to be_between(image.size, image.size * 1.5)
      end
    end

    context 'with a JPEG file (no alpha channel)' do
      let(:image) { file_fixture("image-no-exif.jpg") }

      # Non-regression test: validates watermarking works on JPEG images,
      # which have no alpha channel. The fix uses bandjoin instead of
      # addalpha for compatibility with older libvips versions.
      it 'returns a watermarked tempfile' do
        Tempfile.create(["watermarked", ".jpg"]) do |output|
          watermark_service.process(image, output)
          expect(output.size).to be > 0
        end
      end
    end
  end

  describe '#apply' do
    before { require "vips" }

    it 'returns a Vips::Image with watermark applied on PNG' do
      image = Vips::Image.new_from_file(file_fixture("logo_test_procedure.png").to_path)
      result = watermark_service.apply(image, format: "image/png")

      expect(result).to be_a(Vips::Image)
      expect(result.width).to eq(image.width)
      expect(result.height).to eq(image.height)
      expect(result.has_alpha?).to be true
    end

    it 'flattens alpha when format is JPEG' do
      image = Vips::Image.new_from_file(file_fixture("image-no-exif.jpg").to_path)
      result = watermark_service.apply(image, format: "image/jpeg")

      expect(result).to be_a(Vips::Image)
      expect(result.has_alpha?).to be false
    end

    it 'raises WatermarkService::Error on Vips failure' do
      image = Vips::Image.new_from_file(file_fixture("logo_test_procedure.png").to_path)
      allow(image).to receive(:colourspace).and_raise(Vips::Error.new("boom"))

      expect { watermark_service.apply(image, format: "image/png") }.to raise_error(WatermarkService::Error, /boom/)
    end
  end
end
