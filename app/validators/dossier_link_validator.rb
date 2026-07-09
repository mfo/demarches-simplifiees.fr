# frozen_string_literal: true

class DossierLinkValidator < ActiveModel::Validator
  # Pure function of (value, type_de_champ, user) so prefill screening can
  # share the existence and allowed-procedures queries with the AR validation.
  # Returns an array of [error_key, details] pairs.
  def self.violations(value, type_de_champ, user:)
    existence = existence_violations(value)
    return existence if existence.any?

    allowed_procedures_violations(value, type_de_champ, user)
  end

  def validate(champ)
    self.class.violations(champ.value, champ.type_de_champ, user: champ.dossier.user).each do |error, details|
      champ.errors.add(:value, error, **details)
    end
  end

  class << self
    private

    def existence_violations(value)
      linked_dossier = Dossier.find_by(id: value)
      if linked_dossier.nil? && !DeletedDossier.exists?(dossier_id: value)
        [[:not_found, {}]]
      elsif linked_dossier&.brouillon?
        [[:brouillon_not_allowed, {}]]
      else
        []
      end
    end

    def allowed_procedures_violations(value, type_de_champ, user)
      return [] if !type_de_champ.procedures_limit?

      allowed_ids = type_de_champ.dossier_link_procedure_ids
      return [] if allowed_ids.empty?

      dossier_matches = Dossier.joins(:revision).exists?(id: value, user:, procedure_revisions: { procedure_id: allowed_ids })
      deleted_dossier_matches = DeletedDossier.exists?(dossier_id: value, user_id: user&.id, procedure_id: allowed_ids)

      if dossier_matches || deleted_dossier_matches
        []
      else
        [[:not_in_allowed_procedures, {}]]
      end
    end
  end
end
