# frozen_string_literal: true

class FetchCadastreRealGeometryJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound
  discard_on ActiveJob::DeserializationError

  def perform(geo_area)
    parcelle_data = APIIgn::API.fetch_parcelle(id: geo_area.parcelle_id)
    if parcelle_data.present?
      geo_area.update_columns(
        cadastre_state: :cadastre_fetched,
        geometry: parcelle_data
      )
      # On a brouillon, the dépôt will take care of it. But the fetch can also
      # land afterwards (Cron::FallbackFetchCadastreRealGeometryJob), in which
      # case the image frozen at dépôt would show the approximate geometry.
      champ = geo_area.champ_data
      RenderCarteChampJob.enqueue_for(champ) if !champ.dossier.brouillon?
    else
      geo_area.update_columns(
        cadastre_state: :cadastre_error,
        cadastre_error: :not_found
      )
    end
  rescue ArgumentError
    if executions == MAX_ATTEMPTS_JOBS
      geo_area.update_columns(
        cadastre_state: :cadastre_error,
        cadastre_error: :api_error
      )
    end
  end
end
