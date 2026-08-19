# frozen_string_literal: true

# libvips picks its decoder from a file's leading bytes, whatever content type we
# recorded, so what it agrees to decode IS our attack surface. The initializer narrows
# it to an allow list; this spec is what tells us the list is the one we think it is.
#
# The positive cases matter as much as the negative one: Vips.block silently ignores a
# class name it does not know, and libvips renames those classes between versions. A
# stale name would leave a format blocked, the upload would still succeed, and only the
# missing thumbnail would show it — in production.
describe "libvips allowed loaders", :external_deps do
  let(:path) { Rails.root.join("tmp/#{SecureRandom.hex}") }

  after { FileUtils.rm_f(path) }

  # image/vnd.dwg is authorized but has no libvips decoder, hence its absence here.
  {
    "image/jpeg" => "image-no-exif.jpg",
    "image/png" => "logo_test_procedure.png",
    "image/tiff" => "pencil.tiff",
    "image/webp" => "logo_test_procedure.webp",
    "image/gif" => "french-flag.gif",
  }.each do |content_type, fixture|
    it "still decodes #{content_type}, which we accept and turn into variants" do
      image = Vips::Image.new_from_file(file_fixture(fixture).to_path, access: :sequential)

      expect(image.width).to be_positive
    end
  end

  # StaticMapService rasterises the overlay it builds itself through librsvg.
  it "still decodes the SVG overlay we build ourselves" do
    svg = %(<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"/>)

    expect(Vips::Image.new_from_buffer(svg, '').width).to eq(8)
  end

  # A PPM: unfuzzed decoder, and a format Marcel does not recognize, so it used to
  # reach libvips carrying whatever image type the browser derived from the filename.
  it "refuses a file whose leading bytes select a decoder we did not allow" do
    path.binwrite("P6\n2 2\n255\n#{"\xff\x00\x00" * 4}")

    expect { Vips::Image.new_from_file(path.to_s, access: :sequential) }
      .to raise_error(Vips::Error, /is not a known file format/)
  end

  # Active Storage funnels every variant through ImageProcessing, so this is the path
  # a user-supplied file actually takes.
  it "refuses it through the variant path too" do
    path.binwrite("P6\n2 2\n255\n#{"\xff\x00\x00" * 4}")

    expect { ImageProcessing::Vips.source(path.to_s).convert("png").call }
      .to raise_error(Vips::Error, /is not a known file format/)
  end
end
