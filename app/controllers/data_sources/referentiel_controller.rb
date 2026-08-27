# frozen_string_literal: true

class DataSources::ReferentielController < DataSources::BaseController
  before_action :mark_as_retryable, :set_dossier, :referentiel, :referentiel_service
  MIN_QUERY_LENGTH = 3
  MAX_QUERY_SIZE = 100

  def search
    if query && params[:referentiel_id].present?
      return render json: [] if !referentiel&.autocomplete_ready?

      begin
        result = referentiel_service.call(query, dossier: @dossier)

        case result
        in Dry::Monads::Success
          formatted = ReferentielAutocompleteRenderService.new(result.value!, referentiel).format_response
          return render json: formatted
        in Dry::Monads::Failure(data) if data[:retryable]
          raise RetryableError if @retryable
          Sentry.set_extras(body: data[:body], code: data[:code]) if data.is_a?(Hash)
          Sentry.capture_message("Referentiel API retryable failure")
        in Dry::Monads::Failure(data)
          Sentry.set_extras(body: data[:body], code: data[:code]) if data.is_a?(Hash)
          Sentry.capture_message("Referentiel API failure")
        end
      rescue RetryableError
        @retryable = false
        retry
      rescue StandardError => e
        Sentry.capture_exception(e)
      end
    end
    render json: []
  end

  private

  def authenticate_data_source_user!
    authenticate_user!
  end

  def mark_as_retryable
    @retryable = true
  end

  def referentiel_service
    @referentiel_service ||= ReferentielService.new(referentiel: referentiel, timeout:)
  end

  def timeout
    ReferentielService::API_TIMEOUT / 2 # due to retry
  end

  def query
    return nil if params[:q].blank?
    return nil if params[:q].length < MIN_QUERY_LENGTH
    return nil if params[:q].length > MAX_QUERY_SIZE

    @query ||= params[:q].strip
  end

  def referentiel
    return @referentiel if defined?(@referentiel)

    @referentiel = authorized_referentiel
  end

  def authorized_referentiel
    return nil if @dossier.nil? || params[:referentiel_id].blank?

    candidate = Referentiel.find_by(id: params[:referentiel_id])
    return nil if candidate.nil?

    candidate if @dossier.procedure.active_revision.type_de_champs.any? { it.referentiel_id == candidate.id }
  end

  def set_dossier
    return if params[:dossier_id].blank?

    @dossier = current_user.dossiers.find_by(id: params[:dossier_id]) ||
      current_user.instructeur&.dossiers&.find_by(id: params[:dossier_id])

    DossierPreloader.load_one(@dossier) if @dossier
  end

  class RetryableError < StandardError; end
end
