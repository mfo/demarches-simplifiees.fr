# frozen_string_literal: true

# Renders the static image of a carte champ and attaches it to the champ, so
# that PDF exports find a map ready instead of building one inline.
class RenderCarteChampJob < ApplicationJob
  # The PDF is only asked for after the fact: nothing here should come before
  # work triggered by a usager action.
  queue_as :low

  discard_on ActiveJob::DeserializationError
  discard_on ActiveRecord::RecordNotFound
  # The geometry vanished between enqueueing and running: nothing to render.
  discard_on StaticMapService::EmptyGeometryError

  # No retry_on for RetryableFetchError (IGN WMS unreachable): ApplicationJob's
  # 25 polynomially spaced attempts span hours, enough to ride out an outage.
  #
  # Not as a const: vips is loaded at runtime (cf. BlobProcessorJob). Without
  # this line, a deterministic vips failure (librsvg missing) would run through
  # ApplicationJob's 25 attempts, per champ.
  retry_on "Vips::Error", attempts: 3

  # The render is triggered on dépôt and on every submission of changes (cf.
  # DossierStateConcern), not on every drawing gesture: one job per submission,
  # and nothing while the usager is still filling in their brouillon.
  #
  # `after_all_transactions_commit` because the submissions enqueue from inside
  # the transaction that merges the buffer stream: without it the job could read
  # the geometry from before the merge and freeze a stale image.
  def self.enqueue_for(champ)
    ActiveRecord.after_all_transactions_commit { perform_later(champ) }
  end

  # Only the geometry and the source affect the render: the other properties
  # (champ label, description...) must not cause a new one.
  def self.digest(feature_collection)
    Digest::SHA256.hexdigest(
      feature_collection[:features]
        .map { [it[:geometry], it.dig(:properties, :source)] }
        .to_json
    )
  end

  def perform(champ)
    if !champ.geometry?
      champ.purge_static_map
      return
    end

    feature_collection = champ.to_feature_collection
    digest = self.class.digest(feature_collection)
    # A submission that did not touch the map, or a geometry back to its
    # previous state: the image already in place will do.
    return if champ.static_map_up_to_date?(digest)

    image = StaticMapService.render(feature_collection)
    champ.attach_static_map(StringIO.new(image), digest:)
  end
end
