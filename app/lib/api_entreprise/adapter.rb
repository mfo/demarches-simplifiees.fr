# frozen_string_literal: true

class APIEntreprise::Adapter
  UNAVAILABLE = 'Donnée indisponible'

  include Dry::Monads[:result]

  def initialize(siret, procedure_id)
    @siret = siret
    @procedure_id = procedure_id
  end

  def to_params
    case get_resource
    in Success(body)
      @data_source = body
      Success(process_params)
    in Failure(type: :not_found, **)
      Success({})
    in Failure => failure
      failure
    end
  end

  private

  attr_reader :data_source

  def api(procedure_id = nil)
    APIEntreprise::API.new(procedure_id)
  end

  def valid_params?(params)
    !params.has_value?(UNAVAILABLE)
  end

  def siren
    @siret[0..8]
  end
end
