# frozen_string_literal: true

module Ami
  class Client
    include Dry::Monads[:result]

    EVENT_PATH = "/api/v2/event"

    # PUT et non POST : l'événement est identifié par le partenaire et l'objet
    # associé, donc un rejeu ne crée pas de doublon (200 s'il existait, 201 sinon).
    def send_notification(payload)
      handle_result(API::Client.new.call(url: build_url(EVENT_PATH), json: payload, method: :put, userpwd: credentials))
    end

    def configured?
      api_url.present? && api_user.present? && api_password.present?
    end

    private

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
