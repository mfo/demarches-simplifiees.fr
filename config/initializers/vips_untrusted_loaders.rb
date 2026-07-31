# frozen_string_literal: true

# libvips chooses its decoder from a file's leading bytes, independently of the
# content type we recorded. Several of its loaders are flagged "untrusted": they are
# unfuzzed and only meant for content we produced ourselves, and handing them a
# user-supplied file can do more than fail to produce an image.
#
# Stopping the handoff is the control that works, because it applies at the layer
# that actually picks the decoder. Re-deriving the content type in Ruby does not
# close it: Rails and libvips read the same bytes and disagree, and a third opinion
# does not stop the handoff.

# Active Storage funnels every variant through this one method, so guarding it covers
# the whole variant path. Our own calls go through TrustedVipsLoader directly. Both
# constants are resolved when the method runs rather than while this file loads, so
# autoloading applies as usual and libvips is only needed once an image is decoded.
module VipsLoaderGuard
  def load_image(path_or_image, **options)
    TrustedVipsLoader.ensure_allowed!(path_or_image) if !path_or_image.is_a?(::Vips::Image)

    super
  end
end

begin
  require "vips"
  require "image_processing/vips"
rescue LoadError
  # libvips is installed on the job servers only. Web processes never decode an
  # image — they serve variants a job already produced — so there is nothing to
  # guard here, and requiring it would break their boot.
else
  ImageProcessing::Vips::Processor.singleton_class.prepend(VipsLoaderGuard)

  # From libvips 8.13 on, the same thing enforced inside libvips itself. It is
  # stricter than the guard above — it covers call sites we did not think to wrap —
  # so apply it whenever it exists and treat the Ruby guard as the fallback for
  # older builds, which have no such switch at all.
  if Vips.respond_to?(:block_untrusted)
    Vips.block_untrusted(true)
  else
    libvips_version = "#{Vips.version(0)}.#{Vips.version(1)}.#{Vips.version(2)}"
    message = "libvips #{libvips_version} cannot block untrusted loaders (8.13 or later required). " \
              "Only the decoders named in TrustedVipsLoader::BLOCKED_LOADERS are refused; the rest of " \
              "the unfuzzed family stays reachable until libvips is upgraded."

    warn(message)
    Rails.logger&.warn(message)
  end
end

# Rails' default list also covers formats we never accept (BMP, ICO, PSD, HEIC),
# whose loaders are unfuzzed and would now be refused anyway. Keep the types we
# actually authorize. Independent of libvips being loadable here.
Rails.application.config.active_storage.variable_content_types =
  AUTHORIZED_IMAGE_TYPES & %w[image/jpeg image/png image/tiff image/webp image/gif]
