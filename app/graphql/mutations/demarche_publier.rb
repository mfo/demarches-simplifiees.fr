# frozen_string_literal: true

module Mutations
  class DemarchePublier < Mutations::BaseMutation
    description "Publier une démarche"

    argument :demarche, Types::DemarcheDescriptorType::FindDemarcheInput, "La démarche", required: true
    argument :path, String, "Chemin de la démarche (ne doit pas être utilisé par une autre démarche)", required: true
    argument :lien_site_web, String, "Où les usagers trouveront-ils le lien vers la démarche", required: false
    argument :robots_indexable, Boolean, "Cette démarche est référençable par les moteurs de recherche (Google, …) pour aider les usagers à la découvrir", required: false, default_value: true

    field :demarche, Types::DemarcheDescriptorType, null: true
    field :errors, [Types::ValidationErrorType], null: true
    field :warnings, [Types::WarningMessageType], null: true

    def resolve(demarche:, path:, lien_site_web: nil, robots_indexable:)
      demarche_number = demarche.number.presence || ApplicationRecord.id_from_typed_id(demarche.id)
      demarche = Procedure.find_by(id: demarche_number)

      unless demarche.present? && context.authorized_demarche?(demarche)
        return { errors: ["La démarche \"#{demarche_number}\" n'existe pas ou vous n'avez pas le droit de la publier."] }
      end
      if demarche.publiee_or_close?
        return { warnings: ["La démarche \"#{demarche_number}\" est déjà publiée ou cloturée."] }
      end

      if demarche.other_procedure_with_path(path)
        return { errors: ["Il existe déjà une démarche avec le chemin \"#{path}\"."] }
      end

      demarche.assign_attributes(robots_indexable: robots_indexable, lien_site_web: lien_site_web)

      if demarche.lien_site_web.blank?
        return { errors: ["L'information \"Où trouver la démarche\" est obligatoire (\"lienSiteWeb\")."] }
      end

      demarche.publish_or_reopen!(current_administrateur, path)
      { demarche: }
    rescue ActiveRecord::RecordInvalid
      { errors: demarche.errors.full_messages }
    end
  end
end
