# frozen_string_literal: true

module Types
  class DossierAssignmentType < Types::BaseObject
    class DossierAssignmentMode < Types::BaseEnum
      # i18n-tasks-use t('activerecord.attributes.dossier_assignment.modes.auto'), t('activerecord.attributes.dossier_assignment.modes.manual'), t('activerecord.attributes.dossier_assignment.modes.tech'), t('activerecord.attributes.dossier_assignment.modes.bulk_routing')
      DossierAssignment.modes.each_key do |mode|
        value(mode, I18n.t(mode, scope: [:activerecord, :attributes, :dossier_assignment, :modes]), value: mode)
      end
    end

    description "Une affectation d’un dossier à un groupe instructeur"

    field :mode, DossierAssignmentMode, "Origine de l’affectation.", null: false
    field :assigned_at, GraphQL::Types::ISO8601DateTime, "Date de l’affectation.", null: false
    field :assigned_by, String, "Email de l’agent à l’origine de l’affectation.", null: true
    field :groupe_instructeur_number, Int, "Numéro du groupe instructeur affecté. Null si le groupe a depuis été supprimé.", null: true, method: :groupe_instructeur_id
    field :groupe_instructeur_label, String, "Libellé du groupe instructeur affecté, au moment de l’affectation.", null: false
    field :previous_groupe_instructeur_number, Int, "Numéro du groupe instructeur précédent. Null s’il s’agit de la première affectation ou si le groupe a depuis été supprimé.", null: true, method: :previous_groupe_instructeur_id
    field :previous_groupe_instructeur_label, String, "Libellé du groupe instructeur précédent, au moment de l’affectation.", null: true

    # les colonnes dénormalisées portent le libellé historique : on ne passe pas
    # par les associations, qui donneraient le libellé courant (et un N+1).
    def groupe_instructeur_label = object[:groupe_instructeur_label]

    def previous_groupe_instructeur_label = object[:previous_groupe_instructeur_label]
  end
end
