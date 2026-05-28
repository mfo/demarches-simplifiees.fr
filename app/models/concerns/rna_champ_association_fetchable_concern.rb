# frozen_string_literal: true

module RNAChampAssociationFetchableConcern
  extend ActiveSupport::Concern
  include Dry::Monads[:result]

  def fetch_association!(rna)
    value = rna
    case APIEntreprise::RNAAdapter.new(rna, procedure_id).to_params
    in Success(data)
      update_external_data!(data: data.presence, value:)
      true
    in Failure(retryable: true, **) => result if !APIEntreprise::HealthChecker.provider_up?(:djepva_association)
      update_external_data!(data: nil, value:)
      errors.add(:value, :network_error)
      false
    in Failure => result
      update_external_data!(data: nil, value:)
      APIEntrepriseService.report_error(result.failure, dossier_id:, rna:)
      false
    end
  end
end
