# frozen_string_literal: true

class ReferentielService
  def test
    case type_de_champ.referentiel_adapter
    when 'url'
      ReferentielApiClient.new(type_de_champ:).valid?(type_de_champ.referentiel_test_data)
    else
      fail "not yet implemented: #{type_de_champ.referentiel_adapter}"
    end
  end

  private

  attr_reader :type_de_champ
  def initialize(type_de_champ:)
    @type_de_champ = type_de_champ
  end

  class ReferentielApiClient
    attr_reader :type_de_champ
    def initialize(type_de_champ:)
      @type_de_champ = type_de_champ
    end

    def valid?(value)
      case call(value)
      when Dry::Monads[:result]::Success
        true
      else
        false
      end
    end

    def call(value) = API::Client.new.(url: build_url(value))

    def build_url(value)
      original_url = @type_de_champ.referentiel_url

      original_url.gsub('{id}', value)
    end
  end
end
