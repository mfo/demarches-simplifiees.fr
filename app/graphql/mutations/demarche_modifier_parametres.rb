# frozen_string_literal: true

module Mutations
  class DemarcheModifierParametres < Mutations::BaseMutation
    description "Modifier les paramètres d’une démarche."

    class DeclarativeWithState < GraphQL::Schema::Enum
      value "non_declarative", "La démarche n'est pas déclarative"
      value "en_instruction", "La démarche est en instruction"
      value "accepte", "La démarche est acceptée"
    end

    argument :demarche, Types::DemarcheDescriptorType::FindDemarcheInput, "La démarche", required: true
    argument :title, String, "Le titre de la démarche.", required: false
    argument :description, String, "La description de la démarche.", required: false
    argument :description_target_audience, String, "La description de à qui s'addresse la démarche.", required: false
    argument :description_pj, String, "La description des pièces jointes demandées dans la démarche.", required: false
    argument :lien_site_web, String, "La description de où se trouve le lien de la démarche.", required: false
    argument :lien_dpo, String, "Lien ou adresse électronique pour contacter le DPO", required: false
    argument :date_limite, GraphQL::Types::ISO8601Date, "La date limite de dépot des dossier", required: false
    argument :declarative, DeclarativeWithState, "Est-ce que la démarche est déclarative", required: false

    field :demarche, Types::DemarcheDescriptorType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(demarche:,
      title: nil,
      description: nil,
      description_target_audience: nil,
      description_pj: nil,
      lien_site_web: nil,
      lien_dpo: nil,
      date_limite: nil,
      declarative: nil)
      demarche_number = demarche.number.presence || ApplicationRecord.id_from_typed_id(demarche.id)
      demarche = Procedure.with_active_revision.find_by(id: demarche_number)

      if demarche.blank? || !context.authorized_demarche?(demarche)
        return { errors: ["La démarche \"#{demarche_number}\" n'existe pas ou vous n'avez pas le droit de la modifer."] }
      end

      attrs = {}
      attrs[:libelle] = title if title.present?
      attrs[:description] = description if description.present?
      attrs[:description_target_audience] = description_target_audience if description_target_audience.present?
      attrs[:description_pj] = description_pj if description_pj.present?
      attrs[:lien_site_web] = lien_site_web if lien_site_web.present?
      attrs[:lien_dpo] = lien_dpo if lien_dpo.present?

      if date_limite.present?
        if date_limite.future?
          attrs[:auto_archive_on] = date_limite
        else
          return { errors: ["La date limite doit être dans le futur."] }
        end
      end

      if declarative.present?
        attrs[:declarative_with_state] = declarative == 'non_declarative' ? nil : declarative
      end

      return { errors: ["Aucun paramètre à modifier."] } if attrs.empty?

      unless demarche.update(attrs)
        return { errors: demarche.errors.full_messages }
      end

      demarche.reload
      { demarche: }
    end
  end
end
