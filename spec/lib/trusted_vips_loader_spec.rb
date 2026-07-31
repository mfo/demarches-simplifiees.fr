# frozen_string_literal: true

describe TrustedVipsLoader do
  let(:path) { Rails.root.join("tmp/#{SecureRandom.hex}") }

  after { FileUtils.rm_f(path) }

  # These ten bytes are all libvips reads to route a file to the MATLAB decoder,
  # whatever the file is named or declared as.
  it "refuses a file whose leading bytes select the MATLAB decoder" do
    path.binwrite("MATLAB 5.0 MAT-file#{' ' * 512}")

    expect { described_class.new_from_file(path.to_s) }
      .to raise_error(Vips::Error, /is not a known file format/)
  end

  it "loads an image format we accept" do
    path.binwrite(Rails.root.join("spec/fixtures/files/logo_test_procedure.png").binread)

    expect(described_class.new_from_file(path.to_s).width).to be_positive
  end

  it "accepts a source responding to path" do
    path.binwrite(Rails.root.join("spec/fixtures/files/logo_test_procedure.png").binread)

    expect(described_class.new_from_file(File.open(path)).width).to be_positive
  end

  # Pins the scope of the deny list: other decoders libvips flags as unfuzzed, such as
  # the PDF one the watermark path can reach, are deliberately still let through, since
  # naming them wrongly would reject real uploads. Only libvips 8.13 or later refuses
  # the whole family, via Vips.block_untrusted.
  describe "the decoders it lets through" do
    it "does not refuse a PDF" do
      path.binwrite(Rails.root.join("spec/fixtures/files/Contrat.pdf").binread)

      expect(described_class).to be_allowed(path.to_s)
    end
  end
end
