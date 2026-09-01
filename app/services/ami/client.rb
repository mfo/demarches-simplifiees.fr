# frozen_string_literal: true

module Ami
  class Client
    include Dry::Monads[:result]

    EVENT_PATH = "/api/v2/event"

    # PUT et non POST : l'événement est identifié par le partenaire et l'objet
    # associé, donc un rejeu ne crée pas de doublon (200 s'il existait, 201 sinon).
    def send_notification(payload)
      handle_result(call_api(url: build_url(EVENT_PATH), json: payload, method: :put))
    end

    def configured?
      api_url.present? && api_user.present? && api_password.present?
    end

    private

    def call_api(**options)
      result = API::Client.new.call(userpwd: credentials, **options)
      log_api_call(options, result)
      result
    end

    # Les échanges avec AMI sont invisibles depuis l'application : en
    # développement, on trace une ligne par appel, suivable avec un simple
    # `tail -f log/development.log | grep '\[AMI\]'`. Volontairement limitée à
    # l'URL, la méthode et le code : ni payload ni réponse, donc aucune donnée
    # métier dans les logs.
    def log_api_call(options, result)
      return if !Rails.env.development?

      verb = options.fetch(:method, :get).to_s.upcase
      Rails.logger.info("[AMI] #{verb} #{options.fetch(:url).path} → #{response_code_for(result)}")
    end

    # Une trace de confort ne doit jamais casser l'appel qu'elle observe : on ne
    # suppose pas la forme du résultat.
    def response_code_for(result)
      case result
      in Success(API::Client::OK => ok) then ok.response.code
      in Failure(API::Client::Error => error) then error.code
      else "?"
      end
    end

    def api_url = ENV.fetch("AMI_API_URL", nil)
    def api_user = ENV.fetch("AMI_API_USER", nil)
    def api_password = ENV.fetch("AMI_API_PASSWORD", nil)
    def credentials = "#{api_user}:#{api_password}"

    def build_url(path)
      uri = URI(api_url)
      uri.path = path
      uri
    end

    def handle_result(result)
      case result
      in Success(body:)
        Success(body)
      in Failure(API::Client::Error => error)
        Failure(error)
      end
    end
  end
end
