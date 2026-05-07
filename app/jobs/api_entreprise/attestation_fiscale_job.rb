# frozen_string_literal: true

class APIEntreprise::AttestationFiscaleJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id, user_id)
    find_etablissement(etablissement_id)
    with_adapter(APIEntreprise::AttestationFiscaleAdapter.new(etablissement.siret, procedure_id, user_id)) do |params|
      attestation_fiscale_url = params.delete(:entreprise_attestation_fiscale_url)
      etablissement.upload_attestation_fiscale(attestation_fiscale_url) if attestation_fiscale_url.present?
    end
  end
end
