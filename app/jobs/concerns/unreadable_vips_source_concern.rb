# frozen_string_literal: true

# Browsers derive an upload's content type from its filename, so a file that is not the
# image it claims to be is accepted at upload and only fails later, in image processing:
#
#   Vips::Error: VipsForeignLoad: "/tmp/ActiveStorage-123-abc.jpg" is not a known file format
#
# Those bytes will never become an image, so retrying cannot help and reporting it says
# nothing actionable about the code. Matched narrowly on purpose: every other vips
# failure (memory pressure, temp file trouble) is transient and keeps its retries.
module UnreadableVipsSourceConcern
  extend ActiveSupport::Concern

  UNREADABLE_SOURCE = /is not a known file format/

  private

  def unreadable_vips_source?(error)
    UNREADABLE_SOURCE.match?(error.message)
  end
end
