# frozen_string_literal: true

# Affiche le numéro d'un dossier lié auquel l'instructeur n'a pas accès,
# sous forme de lien déclenchant une modale DSFR.
# - S'il existe des administrateurs de la démarche partageant le domaine email
#   de l'instructeur, leurs adresses sont proposées en lien mailto pour qu'il
#   leur demande l'accès.
# - Sinon, la modale invite à contacter le service en charge de la démarche et
#   affiche ses coordonnées, sans exposer aucune adresse d'administrateur.
class Dossiers::NoAccessToDossierComponent < ApplicationComponent
  def initialize(dossier, instructeur)
    @dossier = dossier
    @instructeur = instructeur
    @procedure = dossier.procedure
  end

  private

  attr_reader :dossier, :instructeur, :procedure

  def procedure_name = procedure.libelle

  def service = procedure.service

  def administrateurs_emails
    @administrateurs_emails ||= begin
      domain = email_domain(instructeur.email)

      procedure.administrateurs
        .map(&:email)
        .filter { email_domain(it) == domain }
    end
  end

  def email_domain(email)
    email.split("@").last.downcase
  end

  def modal_id
    "modal-no-access-to-dossier-#{dossier.id}"
  end
end
