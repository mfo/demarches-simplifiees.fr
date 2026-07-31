# frozen_string_literal: true

# libvips picks its decoder from a file's leading bytes, whatever content type we
# recorded for the blob. It flags several of its decoders as unfuzzed, meaning they
# are only meant for content we produced ourselves, and reading a user-supplied file
# with one of them can have effects well beyond returning an image. From libvips 8.13
# on they can be disabled outright; before that there is no such switch, so we ask
# which decoder libvips would choose and refuse the ones listed below.
#
# Deliberately a deny list rather than an allow list. An allow list would also have
# to name every decoder a legitimate upload may go through, and those names are read
# from a newer libvips than the one we deploy — an entry we got wrong would reject
# real files. This errs the other way: it only stops what we have named.
module TrustedVipsLoader
  # Reads MATLAB files, via a library whose format handling reaches well outside the
  # file it was given. Nothing we accept is ever decoded by it.
  BLOCKED_LOADERS = %w[
    VipsForeignLoadMat
  ].freeze

  class << self
    def new_from_file(source, **options)
      ensure_allowed!(source)

      Vips::Image.new_from_file(path_for(source), **options)
    end

    # Raised with the message UnreadableVipsSourceConcern already reads as "these bytes
    # will never be an image", so a refused file is skipped rather than retried.
    def ensure_allowed!(source)
      return if allowed?(source)

      raise Vips::Error, "#{path_for(source)} is not a known file format"
    end

    def allowed?(source)
      !Vips.vips_foreign_find_load(path_for(source)).in?(BLOCKED_LOADERS)
    end

    private

    def path_for(source)
      source.respond_to?(:path) ? source.path.to_s : source.to_s
    end
  end
end
