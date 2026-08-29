# frozen_string_literal: true

class SerializerService
  # Dossier-level serialization (audit log) runs the public stored query so the
  # recorded shape stays the one integrators see. File URLs are transient signed
  # links, so they are left out of what gets written to the log.
  DOSSIER_VARIABLES = {
    includeChamps: false,
    includeAnnotations: false,
    includeTraitements: false,
    includeInstructeurs: false,
    includeFileUrls: false,
  }.freeze

  def self.dossier(dossier)
    Sentry.with_scope do |scope|
      scope.set_tags(dossier: dossier.id)

      data = execute_stored_query(
        number: dossier.id,
        includeChamps: true,
        includeAnnotations: true,
        includeTraitements: true,
        includeInstructeurs: true,
        includeAvis: true
      )
      data && data['dossier']
    end
  end

  def self.demarches_publiques(after: nil)
    data = execute_query('serializeDemarchesPubliques', { after: after })
    data && data['demarcheDescriptors']
  end

  def self.avis(avis)
    data = execute_stored_query(number: avis.dossier_id, avisId: avis.to_typed_id, includeAvis: true)
    data && data['dossier']['avis'].first
  end

  def self.champ(champ)
    Sentry.with_scope do |scope|
      scope.set_tags(champ: champ.id)

      if champ.private?
        data = execute_stored_query(number: champ.dossier_id, annotationId: champ.to_typed_id, includeAnnotations: true)
        data && data['dossier']['annotations'].first
      else
        data = execute_stored_query(number: champ.dossier_id, champId: champ.to_typed_id, includeChamps: true)
        data && data['dossier']['champs'].first
      end
    end
  end

  def self.message(commentaire)
    Sentry.with_scope do |scope|
      scope.set_tags(dossier: commentaire.dossier_id)

      data = execute_stored_query(number: commentaire.dossier_id, messageId: commentaire.to_typed_id, includeMessages: true)
      data && data['dossier']["messages"].first
    end
  end

  def self.execute_stored_query(number:, **variables)
    execute_query('getDossier', DOSSIER_VARIABLES.merge(dossierNumber: number, **variables), query: API::V2::StoredQuery::QUERY_V2)
  end

  def self.execute_query(operation_name, variables, query: QUERY)
    result = API::V2::Schema.execute(query,
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

  QUERY = <<-'GRAPHQL'
    query serializeDemarchesPubliques($after: String) {
      demarcheDescriptors(after: $after) {
        nodes {
          ...DemarcheDescriptorFragment
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }

    fragment FileFragment on File {
      filename
      checksum
      byteSize: byteSizeBigInt
      contentType
      virusScanResult
    }

    fragment ChampDescriptorFragment on ChampDescriptor {
      __typename
      label
      description
      required
      ... on DropDownListChampDescriptor {
        options
        otherOption
      }
      ... on MultipleDropDownListChampDescriptor {
        options
      }
      ... on LinkedDropDownListChampDescriptor {
        options
      }
    }

    fragment DemarcheDescriptorFragment on DemarcheDescriptor {
      number
      title
      description
      state
      forIndividual
      tags
      zones
      datePublication
      service { nom organisme typeOrganisme departement }
      demarcheUrl
      dpoUrl
      noticeUrl
      siteWebUrl
      cadreJuridiqueUrl
      logo { ...FileFragment }
      notice { ...FileFragment }
      deliberation { ...FileFragment }
      dossiersCount
      revision {
        champDescriptors {
          ...ChampDescriptorFragment
          ... on RepetitionChampDescriptor {
            champDescriptors {
              ...ChampDescriptorFragment
            }
          }
        }
      }
    }

  GRAPHQL
end
