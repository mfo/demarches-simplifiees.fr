# frozen_string_literal: true

class SerializerService
  # Internal serialization (audit log, datagouv export) runs the public stored
  # queries so the recorded shape stays the one integrators see. File URLs are
  # transient signed links, so they are left out of what gets persisted.
  DOSSIER_VARIABLES = {
    includeChamps: true,
    includeAnnotations: true,
    includeTraitements: true,
    includeInstructeurs: true,
    includeAvis: true,
    includeFileUrls: false,
  }.freeze

  def self.dossier(dossier)
    Sentry.with_scope do |scope|
      scope.set_tags(dossier: dossier.id)

      data = execute_query('getDossier', DOSSIER_VARIABLES.merge(dossierNumber: dossier.id))
      data && data['dossier']
    end
  end

  def self.demarches_publiques(after: nil)
    data = execute_query('getDemarcheDescriptors', { after:, includeRevision: true, includeService: true, includeFileUrls: false })
    data && data['demarcheDescriptors']
  end

  def self.avis(avis)
    data = execute_records_query(number: avis.dossier_id, avisId: avis.to_typed_id, includeAvis: true)
    data && data['dossier']['avis'].first
  end

  def self.champ(champ)
    Sentry.with_scope do |scope|
      scope.set_tags(champ: champ.id)

      if champ.private?
        data = execute_records_query(number: champ.dossier_id, annotationId: champ.to_typed_id, includeAnnotations: true)
        data && data['dossier']['annotations'].first
      else
        data = execute_records_query(number: champ.dossier_id, champId: champ.to_typed_id, includeChamps: true)
        data && data['dossier']['champs'].first
      end
    end
  end

  def self.message(commentaire)
    Sentry.with_scope do |scope|
      scope.set_tags(dossier: commentaire.dossier_id)

      data = execute_records_query(number: commentaire.dossier_id, messageId: commentaire.to_typed_id, includeMessages: true)
      data && data['dossier']["messages"].first
    end
  end

  def self.execute_records_query(number:, **variables)
    execute_query('getDossierRecords', { dossierNumber: number, includeFileUrls: false, **variables })
  end

  def self.execute_query(operation_name, variables)
    result = API::V2::Schema.execute(API::V2::StoredQuery::QUERY_V2,
      variables: variables.stringify_keys,
      context: { internal_use: true },
      operation_name: operation_name)
    if result['errors'].present?
      error_message = result['errors'].first['message']
      Sentry.capture_message("SerializerService execute_query failed: " + error_message)
      raise error_message
    end
    result['data']
  end
end
