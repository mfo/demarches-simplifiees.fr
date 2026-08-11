# frozen_string_literal: true

describe "libvips untrusted loaders", :external_deps do
  let(:path) { Rails.root.join("tmp/#{SecureRandom.hex}") }
  let(:unfuzzed_loader_bytes) { "MATLAB 5.0 MAT-file#{' ' * 512}" }
  let(:accepted_image_bytes) { Rails.root.join("spec/fixtures/files/logo_test_procedure.png").binread }

  after { FileUtils.rm_f(path) }

  # Active Storage funnels every variant through ImageProcessing, so this holds on
  # any libvips version — including the builds before 8.13, which cannot refuse
  # these loaders themselves and rely entirely on TrustedVipsLoader.
  describe "building a variant" do
    before { Vips.block_untrusted(false) if Vips.respond_to?(:block_untrusted) }

    after { Vips.block_untrusted(true) if Vips.respond_to?(:block_untrusted) }

    it "refuses a file whose leading bytes select an unfuzzed loader" do
      path.binwrite(unfuzzed_loader_bytes)

      expect { ImageProcessing::Vips.source(path.to_s).convert("png").call }
        .to raise_error(Vips::Error, /is not a known file format/)
    end

    it "still accepts an image format we authorize" do
      path.binwrite(accepted_image_bytes)

      expect(ImageProcessing::Vips.source(path.to_s).resize_to_limit(50, 50).call).to be_present
    end
  end

  # From 8.13 on, libvips enforces this itself, which also covers any call site we
  # forgot to route through TrustedVipsLoader.
  # Evaluated while this file loads, which also happens in the CI job that has no
  # libvips at all — hence the defined? guard alongside the version check.
  describe "libvips-level blocking", if: defined?(Vips) && Vips.respond_to?(:block_untrusted) do
    it "refuses a file whose leading bytes select an unfuzzed loader" do
      path.binwrite(unfuzzed_loader_bytes)

      expect { Vips::Image.new_from_file(path.to_s, access: :sequential) }
        .to raise_error(Vips::Error, /is not a known file format/)
    end

    it "still accepts an image format we authorize" do
      path.binwrite(accepted_image_bytes)

      expect(Vips::Image.new_from_file(path.to_s, access: :sequential).width).to be_positive
    end
  end
end
