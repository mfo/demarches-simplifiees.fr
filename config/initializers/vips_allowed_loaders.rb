# frozen_string_literal: true

# libvips picks its decoder from a file's leading bytes, whatever content type we
# recorded for the blob. Active Storage blocks the decoders libvips flags as unfuzzed
# (CVE-2026-66066), which still leaves every other decoder reachable. libvips
# documents a finer control for untrusted data: block the whole loader hierarchy,
# then name the ones you actually want.
#
# So this is an allow list, and it is the whole surface: a file whose bytes match
# nothing below is refused by libvips itself, before any decoder reads it. It mirrors
# AUTHORIZED_IMAGE_TYPES — accepting a new image format means adding it here too,
# otherwise the upload succeeds and the thumbnail never comes.
#
# SVG is on the list for our own content only: StaticMapService rasterises through
# librsvg the overlay it has just built — the dossier's geometries and the
# attribution line. No uploaded file reaches it, since image/svg+xml is not an
# authorized content type and a blob whose bytes contradict its declared image type
# is downgraded to binary before it can become variable.
#
# The class names are those of the abstract loader classes, and they cover the file,
# buffer and source variants below them. A name libvips does not know is silently
# ignored, which would leave that format blocked — spec/config/vips_allowed_loaders_spec.rb
# decodes one file of each to catch exactly that.
ALLOWED_VIPS_LOADERS = %w[
  VipsForeignLoadJpeg
  VipsForeignLoadPng
  VipsForeignLoadTiff
  VipsForeignLoadWebp
  VipsForeignLoadNsgif
  VipsForeignLoadSvg
].freeze

if ActiveStorage::VIPS_AVAILABLE
  Vips.block("VipsForeignLoad", true)
  ALLOWED_VIPS_LOADERS.each { Vips.block(it, false) }
end
