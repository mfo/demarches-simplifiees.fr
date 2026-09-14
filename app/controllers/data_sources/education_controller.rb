# frozen_string_literal: true

class DataSources::EducationController < DataSources::BaseController
  def search
    if params[:q].present? && params[:q].length >= 3
      response = fetch_results

      if response.success?
        results = JSON.parse(response.body, symbolize_names: true)

        return render json: format_results(results)
      end
    end

    render json: []

  rescue JSON::ParserError
    Sentry.capture_message("Education API failure", extra: { code: response.code, body: response.body.to_s.truncate(200) })
    render json: []
  end

  private

  def fetch_results
    Typhoeus.get("#{API_EDUCATION_URL}/search", params: { q: params[:q], rows: 5, dataset: 'fr-en-annuaire-education' }, timeout: 3)
  end

  def format_results(results)
    results[:records].map do |record|
      fields = record.fetch(:fields)
      value = fields.fetch(:identifiant_de_l_etablissement)

      commune = fields[:nom_commune].present? ? ", #{fields[:nom_commune]}" : ""

      {
        label: "#{fields.fetch(:nom_etablissement)}#{commune} (#{value})",
        value:,
        data: record,
      }
    end
  end
end
